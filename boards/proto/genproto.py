from pathlib import Path
from KicadModTree import Footprint, KicadFileHandler, ModArgparser, Pad, \
    PadArray, Text


def proto_footprint(args):
    def write_rail_pads(offs, pad_type, pad_layers):
        nonlocal curr_pad

        start_col = args["rail_start_col"] + offs[1]
        end_col = args["num_cols"] - args["rail_start_col"] + 1  # need inclusive indexing  # noqa: E501
        col_step = args["num_rails"]
        start_row = args["rail_start_row"] + offs[0]
        end_row = args["num_rows"] - args["rail_start_row"] + 1  # need inclusive indexing  # noqa: E501
        row_step = args["num_rails"]

        for r in range(start_row, end_row, row_step):
            for c in range(start_col, end_col, col_step):
                rail_hole_row_pos = org_y + (args["offset_rows"] + r)*2.54
                rail_hole_col_pos = org_x + (args["offset_cols"] + c)*2.54

                pad = Pad(at=[rail_hole_col_pos, rail_hole_row_pos],
                          number=curr_pad,
                          type=pad_type,
                          shape=Pad.SHAPE_CIRCLE,
                          size=1.1,
                          drill=0.4,
                          layers=pad_layers)

                kicad_mod.append(pad)
                curr_pad += 1

    def stride(rail, num_rails):
        for i in range(num_rails):
            if i == rail:
                continue
            yield i

    footprint_name = "Prototype Area"

    # Init kicad footprint
    kicad_mod = Footprint(footprint_name)
    kicad_mod.setDescription("Prototype Area footprint")
    kicad_mod.setTags("prototype")

    # Set general values
    kicad_mod.append(Text(type="reference",
                          text="REF**", at=[0, -3], layer="F.SilkS"))
    kicad_mod.append(Text(type="value",
                          text=footprint_name, at=[1.5, 3], layer="F.Fab"))

    org_x = 0  # Attempt to place middle of proto area at
    org_y = -(args["num_rows"] - 1)*2.54/2  # origin by default.

    curr_pad = 1
    for r in range(args["num_rows"]):
        proto_row_x = org_x + (args["offset_cols"])*2.54
        proto_row_y = org_y + (args["offset_rows"] + r)*2.54

        pa = PadArray(pincount=args["num_cols"],
                      spacing=[2.54, 0],
                      center=[proto_row_x, proto_row_y],
                      initial=curr_pad,
                      type=Pad.TYPE_THT,
                      shape=Pad.SHAPE_CIRCLE,
                      size=1.7,
                      drill=1.0,
                      layers=Pad.LAYERS_THT,
                      tht_pad1_shape=Pad.SHAPE_CIRCLE)
        kicad_mod.append(pa)
        curr_pad += args["num_cols"]

    # Convert to pad position rather than pad array center.
    org_x = -args["num_cols"]*2.54/2
    org_y = -args["num_rows"]*2.54/2

    for rail_num in range(args["num_rails"]):
        write_rail_pads((rail_num, rail_num), Pad.TYPE_THT, Pad.LAYERS_THT)

    for rail_num in range(args["num_rails"]):
        for s in stride(rail_num, args["num_rails"]):
            write_rail_pads((s, rail_num), Pad.TYPE_SMT, Pad.LAYERS_SMT)
        for s in stride(rail_num, args["num_rails"]):
            write_rail_pads((rail_num, s), Pad.TYPE_SMT, ["B.Cu",
                                                          "B.Mask",
                                                          "B.Paste"])

    # Calculate the border of the pad array
    # border = pa.calculateOutline()

    # Create a courtyard around the pad array
    # kicad_mod.append(RectLine(start=border['min'], end=border['max'],
    #                  layer='F.Fab', width=0.05, offset=0.5))

    # Write file
    file_handler = KicadFileHandler(kicad_mod)
    file_handler.writeFile(Path("./proto.pretty") / (args["name"] +
                           " Prototype Area.kicad_mod"))


if __name__ == "__main__":
    parser = ModArgparser(proto_footprint)
    parser.add_parameter("name", type=str, required=True)  # the root node of .yml files is parsed as name  # noqa: E501
    # parser.add_parameter("courtyard", type=int, required=False, default=0.25)
    parser.add_parameter("num_rows", type=int, required=False, default=10)
    parser.add_parameter("num_cols", type=int, required=False, default=10)
    parser.add_parameter("offset_rows", type=float, required=False, default=0)
    parser.add_parameter("offset_cols", type=float, required=False, default=0)
    parser.add_parameter("rail_start_row", type=int, required=False, default=1)
    parser.add_parameter("rail_start_col", type=int, required=False, default=1)
    parser.add_parameter("num_rails", type=int, required=False, default=2)

    parser.run()
