from pcbnew import GetBoard

board = GetBoard()
pads = board.GetPads()
nets = board.GetNetsByName()

for p in board.GetPads():
    g = p.GetParentGroup()
    if g and g.GetName() == 'PRI_RAIL':
        p.SetNet(nets["+5V"])
