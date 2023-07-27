use std::io::{self, Read};
use std::{borrow::Cow, path::Path, time::Duration};

use clap::{Parser, Subcommand};
use clap_num::maybe_hex;
use clio;
use eyre::{eyre, Result, WrapErr};
#[allow(unused)]
use log::*;
use memmem::{Searcher, TwoWaySearcher};
use serialport::{self, SerialPort};
use stderrlog::StdErrLog;

/* This was blatantly copied from https://github.com/kalj/sxb (thanks for writing
this!), and then tweaked to my particular dev flow. */

#[derive(clap::Parser)]
#[clap(author, version)]
/// Quick-and-dirty tool to interface to W65C02SXB board (and potentially others)
pub struct Args {
    #[command(flatten)]
    verbose: clap_verbosity_flag::Verbosity,
    pub port: String,
    #[clap(subcommand)]
    pub cmd: Cmd,
}

#[derive(Subcommand)]
pub enum Cmd {
    /// Load binary onto W65C02SXB board
    Load {
        file: clio::Input,
        #[clap(subcommand)]
        format: LoadFormat,
    },
    /// Exec binary onto W65C02SXB board
    Exec {
        #[clap(short='a', long, value_parser=maybe_hex::<u32>, default_value="0x2000")]
        addr: u32,
    },
    /// Load and exec binary onto W65C02SXB board
    LoadExec {
        /// Load and exec address (shared, overrides load address)
        #[clap(short='a', long, value_parser=maybe_hex::<u32>, default_value="0x2000")]
        addr: u32,
        file: clio::Input,
        #[clap(subcommand)]
        format: LoadFormat,
    },
    /// Read W65C02SXB memory space
    Read {
        #[clap(short = 'x', long)]
        /// Format results into hex table
        hex: bool,
        #[clap(value_parser=maybe_hex::<u32>)]
        addr: u32,
        #[clap(value_parser=maybe_hex::<u16>)]
        len: u16,
    },
}

/// Input format of file to load
#[derive(Clone, Subcommand)]
pub enum LoadFormat {
    /// Raw binary file which mirrors what's loaded into W65C02SXB board memory
    Raw {
        #[clap(short='a', long, value_parser=maybe_hex::<u32>, default_value="0x2000")]
        /// Load address onto W65C02SXB board.
        addr: u32,
        /// Do not load interrupt vectors at 0x7efa
        #[clap(long)]
        skip_vec: bool,
        #[clap(flatten)]
        length: RawLength,
    },
}

#[derive(Clone, clap::Args)]
#[group(required = false, multiple = false)]
pub struct RawLength {
    #[clap(short, long)]
    /// Stop loading when binary magic cookie "ba486455aa10b2fb68090d9412e62da2" is found
    magic: bool,
    #[clap(short, long)]
    #[clap(value_parser=maybe_hex::<u32>)]
    length: Option<u32>,
}

mod mon {
    use super::*;
    pub struct WdcMon(Box<dyn SerialPort>);

    impl WdcMon {
        #[allow(unused)]
        const CMD_SYNC: u8 = 0x0;
        #[allow(unused)]
        const CMD_ECHO: u8 = 0x1;
        const CMD_WRITE_MEM: u8 = 0x2;
        const CMD_READ_MEM: u8 = 0x3;
        #[allow(unused)]
        const CMD_GET_INFO: u8 = 0x4;
        const CMD_EXEC_DEBUG: u8 = 0x5;
        const STATE_ADDRESS: u32 = 0x7e00;

        pub fn new<'a, P>(port: P) -> Result<Self>
        where
            P: AsRef<Path>,
            Cow<'a, str>: From<P>,
        {
            Ok(Self(
                serialport::new(port, 57_600)
                    .parity(serialport::Parity::None)
                    .stop_bits(serialport::StopBits::One)
                    .data_bits(serialport::DataBits::Eight)
                    .timeout(Duration::from_millis(600))
                    .open()?,
            ))
        }

        fn initiate_command(&mut self, cmd: u8) -> Result<()> {
            self.0.write(&[0x55, 0xaa])?;

            let mut res = [0; 1];
            self.0.read(&mut res).wrap_err(
                "Did not receive a response when initiating command.\n\
                                Try pressing the NMI button, and try running again.\n\
                                If that didn't work, press the RST button, and try again.",
            )?;

            match res[0] {
                0xcc => {}
                v => {
                    return Err(eyre!(
                        "Unexpected response received when initiating command: {}",
                        v
                    ))
                }
            }

            self.0.write(&cmd.to_le_bytes())?;
            Ok(())
        }

        fn read_memory(&mut self, addr: u32, data: &mut [u8]) -> Result<()> {
            self.initiate_command(Self::CMD_READ_MEM)?;

            let addr_bytes = &mut addr.to_le_bytes()[0..3];
            addr_bytes[2] = 0;
            self.0
                .write(addr_bytes)
                .wrap_err("Could not send address bytes")?;

            self.0
                .write(&data.len().to_le_bytes()[0..2])
                .wrap_err("Could not send length bytes")?;

            self.0.read(data).wrap_err("Did not receive enough data")?;

            Ok(())
        }

        fn write_memory(&mut self, addr: u32, data: &[u8]) -> Result<()> {
            self.initiate_command(Self::CMD_WRITE_MEM)?;

            let addr_bytes = &mut addr.to_le_bytes()[0..3];
            addr_bytes[2] = 0;
            self.0
                .write(addr_bytes)
                .wrap_err("Could not send address bytes")?;

            self.0
                .write(&data.len().to_le_bytes()[0..2])
                .wrap_err("Could not send length bytes")?;

            self.0.write(data).wrap_err("Could not write all data")?;

            Ok(())
        }

        pub fn load_binary(&mut self, mut file: clio::Input, format: LoadFormat) -> Result<()> {
            match format {
                LoadFormat::Raw {
                    addr,
                    skip_vec,
                    length,
                } => {
                    if addr < 0x200 {
                        return Err(eyre!(
                            "Offset {} would overwrite ZP (0x0-0xff) or stack page (0x100-0x1ff)",
                            addr
                        ));
                    }

                    let mut buf = Vec::new();
                    match length {
                        RawLength { magic: true, .. } => {
                            file.read_to_end(&mut buf)?;
                            let search = TwoWaySearcher::new(&[
                                0xBA, 0x48, 0x64, 0x55, 0xAA, 0x10, 0xB2, 0xFB, 0x68, 0x9, 0xD,
                                0x94, 0x12, 0xE6, 0x2D, 0xA2,
                            ]);
                            match search.search_in(&buf) {
                                Some(l) => {
                                    debug!(target: "load_binary", "found magic binary cookie ba486455aa10b2fb68090d9412e62da2 at {}", l);
                                    buf.resize(l as usize, 0);
                                    file.read(&mut buf)?;
                                }
                                None => {
                                    return Err(eyre!("Could not find magic binary cookie ba486455aa10b2fb68090d9412e62da2 in input file"))
                                }
                            }
                        }
                        RawLength {
                            magic: false,
                            length: Some(l),
                        } => {
                            buf.resize(l as usize, 0);
                            file.read(&mut buf)?;
                        }
                        RawLength {
                            magic: false,
                            length: None,
                        } => {
                            buf.resize((0x7c00 - addr) as usize, 0);
                            file.read(&mut buf)?;
                        }
                    }

                    if addr as usize + buf.len() > 0x7c00 {
                        return Err(eyre!("File would overwrite debugger/flash memory (65816 board not supported yet)"));
                    }

                    self.write_memory(addr, &buf)?;

                    if !skip_vec {
                        let offset_to_vecs = 0x7efa - (addr as u64 + buf.len() as u64);
                        io::copy(&mut file.by_ref().take(offset_to_vecs), &mut io::sink())?;
                        buf.truncate(6);
                        file.read(&mut buf)?;

                        self.write_memory(0x7efa, &buf)?;
                    }
                }
            }
            Ok(())
        }

        pub fn exec(&mut self, addr: u32) -> Result<()> {
            let state = [
                0x00,
                0x00, // A
                0x00,
                0x00, // X
                0x00,
                0x00, // Y
                (addr & 0xff) as u8,
                ((addr >> 8) & 0xff) as u8, // PC
                0,                          // 8
                0,                          // 9
                0xff,                       // A stack pointer
                1,                          // B
                0,                          // C processor status bits
                1,                          // D CPU mode (0=65816, 1=6502)
                0,                          // E
                0,                          // F
            ];

            self.write_memory(Self::STATE_ADDRESS, &state)?;
            self.initiate_command(Self::CMD_EXEC_DEBUG)?;

            Ok(())
        }

        pub fn dump_hex(&mut self, start_addr: u32, len: u16) -> Result<()> {
            let mut data = [0; 16];
            for addr in (start_addr..start_addr + len as u32).step_by(16) {
                if addr + 16 >= start_addr + len as u32 {
                    data = [0; 16];
                    let bytes_left = (start_addr + (len as u32) - addr) as usize;
                    self.read_memory(addr, &mut data[0..bytes_left])?;
                } else {
                    self.read_memory(addr, &mut data)?;
                }

                hexy::hexydump(&data, &(addr as usize), &16);
            }

            Ok(())
        }
    }
}

fn main() -> Result<()> {
    let args = Args::try_parse()?;

    StdErrLog::new()
        .verbosity(args.verbose.log_level_filter())
        .init()?;

    match args.cmd {
        Cmd::Load { file, format } => {
            let mut mon = mon::WdcMon::new(args.port)?;
            mon.load_binary(file, format)?;
        }
        Cmd::Exec { addr } => {
            let mut mon = mon::WdcMon::new(args.port)?;
            mon.exec(addr)?;
        }
        Cmd::LoadExec {
            file,
            addr: exec_addr,
            mut format,
        } => {
            match format {
                LoadFormat::Raw {
                    addr: ref mut load_addr,
                    ..
                } => {
                    *load_addr = exec_addr;
                }
            }

            let mut mon = mon::WdcMon::new(args.port)?;
            mon.load_binary(file, format)?;
            mon.exec(exec_addr)?;
        }
        Cmd::Read {
            addr: start_addr,
            len,
            hex: true,
        } => {
            let mut mon = mon::WdcMon::new(args.port)?;
            mon.dump_hex(start_addr, len)?;
        }
        Cmd::Read {
            addr: _start_addr,
            len: _len,
            hex: false,
        } => {
            unimplemented!()
        }
    }

    Ok(())
}
