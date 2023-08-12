# From Python Scripting Console:
# cd("/path/to/genrails.py")
# exec(open("./genrails.py").read())

import json
from pathlib import Path
import pcbnew
from pcbnew import GetBoard, FromMils as FMi, FromMM as FMM


def is_rail_pad(pad):
    return pad.GetSize() == pcbnew.wxSize(FMM(1.1), FMM(1.1))


def find_top_left_proto_pad(pads):
    start_x = min(map(lambda p: p.GetX(), filter(is_rail_pad, pads)))
    start_y = min(map(lambda p: p.GetY(), filter(is_rail_pad, pads)))
    return (start_x, start_y)


def find_bottom_right_proto_pad(pads):
    end_x = max(map(lambda p: p.GetX(), filter(is_rail_pad, pads)))
    end_y = max(map(lambda p: p.GetY(), filter(is_rail_pad, pads)))
    return (end_x, end_y)


with open(Path("./rails.json")) as fp:
    rails = json.load(fp)

board = GetBoard()
pads = board.GetPads()
nets = board.GetNetsByName()
tracks = board.GetTracks()
proto = board.FindFootprintByReference("REF5")

ppads = dict()  # Keys: (Position, Layer). THT pads are stored twice/alias!
for p in proto.Pads():
    if p.IsOnLayer(pcbnew.F_Cu):
        ppads[p.GetPosition().Get(), pcbnew.F_Cu] = p

    if p.IsOnLayer(pcbnew.B_Cu):
        ppads[p.GetPosition().Get(), pcbnew.B_Cu] = p

(start_x, start_y) = find_top_left_proto_pad(ppads.values())
(end_x, end_y) = find_bottom_right_proto_pad(ppads.values())

ptracks = dict()
# Delete tracks. This is not perfect and may delete tracks outside of
# the voltage rail network. But it should rip up everything _inside_.
for t in tracks:
    if t.GetEnd()[0] in (start_x, end_x) or \
       t.GetStart()[0] in (start_x, end_x) or \
       t.GetEnd()[1] in (start_y, end_y) or \
       t.GetStart()[1] in (start_y, end_y):
        print("will delete track ", t.GetStart(), t.GetEnd())
        board.RemoveNative(t)
    else:
        pass
        # print("will preserve track ", t.GetStart(), t.GetEnd())

(x_incr, y_incr) = (len(rails)*FMi(100), len(rails)*FMi(100))

# Clear all nets associated with pads.
for x in range(start_x, end_x + 1, FMi(100)):
    try:
        ppads[(x, start_y), pcbnew.F_Cu]
        ppads[(x, start_y), pcbnew.B_Cu]
        for y in range(start_y, end_y + 1, FMi(100)):
            try:
                curr_pad = ppads[(x, y), pcbnew.F_Cu]
                curr_pad.SetNet(nets[""])
                curr_pad = ppads[(x, y), pcbnew.B_Cu]
                curr_pad.SetNet(nets[""])
            except KeyError:
                print("Y break on ", (x, y))
                break
    except KeyError:
        print("X break on ", (x, start_y))
        break


# (Re)associate nets with pads. Skip over nets with don't exist.
for i, r in enumerate(rails):
    try:
        nets[r]
    except IndexError:
        net = pcbnew.NETINFO_ITEM(board, r)
        board.Add(net)
        print("Cannot find net {}, adding it.".format(r))
        nets = board.GetNetsByName()  # Dict will not be updated unless I
                                      # refresh it manually.  # noqa: E114,E116

    # Top-side. Set vertical strips for each rail.
    for x in range(start_x + i*FMi(100), end_x + 1, x_incr):
        try:
            ppads[(x, start_y), pcbnew.F_Cu]
            for y in range(start_y, end_y + 1, FMi(100)):
                try:
                    curr_pad = ppads[(x, y), pcbnew.F_Cu]
                    curr_pad.SetNet(nets[r])
                except KeyError:
                    print("Y break on ", (x, y))
                    break
        except KeyError:
            print("X break on ", (x, start_y))
            break

        track = pcbnew.PCB_TRACK(board)
        track.SetStart(pcbnew.wxPoint(x, start_y))
        track.SetEnd(pcbnew.wxPoint(x, end_y))
        track.SetWidth(int(0.25 * pcbnew.IU_PER_MM))
        track.SetLayer(pcbnew.F_Cu)
        track.SetNet(nets[r])
        board.Add(track)

    # Bottom-side. Set horizontal strips for each rail.
    for y in range(start_y + i*FMi(100), end_y + 1, y_incr):
        try:
            ppads[(start_x, y), pcbnew.B_Cu]
            for x in range(start_x, end_x + 1, FMi(100)):
                try:
                    curr_pad = ppads[(x, y), pcbnew.B_Cu]
                    curr_pad.SetNet(nets[r])
                except KeyError:
                    print("Y break on ", (x, y))
                    break
        except KeyError:
            print("X break on ", (x, start_y))
            break

        track = pcbnew.PCB_TRACK(board)
        track.SetStart(pcbnew.wxPoint(start_x, y))
        track.SetEnd(pcbnew.wxPoint(end_x, y))
        track.SetWidth(int(0.25 * pcbnew.IU_PER_MM))
        track.SetLayer(pcbnew.B_Cu)
        track.SetNet(nets[r])
        board.Add(track)

        # board.RemoveNative(t)

