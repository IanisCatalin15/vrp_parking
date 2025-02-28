local cfg = {}

cfg.showroom_map = {"PoI", {blip_id = 225, blip_color = 46, marker_id = 1}}
cfg.owned_map = {"PoI", {blip_id = 474, blip_color = 42, marker_id = 1}}
cfg.insurance_map = {"PoI", {blip_id = 473, blip_color = 2, marker_id = 1}}
cfg.parking_map = {"PoI", {blip_id = 357, blip_color = 5, marker_id = 27}}


cfg.showroom_vehicles = {
        { model = "blista", name = "Blista", price = 20000 },
        { model = "brioso", name = "Brioso R/A", price = 25000 },
        { model = "issi2", name = "Issi Classic", price = 18000 },
        { model = "comet2", name = "Comet", price = 120000 },
        { model = "feltzer2", name = "Feltzer", price = 100000 },
        { model = "ninef", name = "9F", price = 150000 },
        { model = "t20", name = "T20", price = 2200000 },
        { model = "adder", name = "Adder", price = 1800000 },
        { model = "cheetah", name = "Cheetah", price = 2000000 }
    }


cfg.showrooms = {
    {-51.42223739624,-1113.0301513672,26.435806274414}
}

cfg.owned = {
    {-13.216364860535,-1081.2995605469,26.672040939331}
  }

cfg.parking_areas = {
    ["Main Parking"] = {  
        slots = {
            {id = 1, pos = {207.18395996094,-798.69781494141,30.986066818237}},
            {id = 2, pos = {210.01522827148,-791.2275390625,30.923738479614}},
            {id = 3, pos = {213.13854980469,-783.76068115234,30.870124816895}},
            {id = 4, pos = {215.58815002441,-776.06036376953,30.845920562744}},
            {id = 5, pos = {218.46699523926,-768.56878662109,30.826971054077}},
            {id = 6, pos = {227.77586364746,-771.61987304688,30.78104019165}},
            {id = 7, pos = {224.31637573242,-778.99011230469,30.76291847229}},
            {id = 8, pos = {222.08676147461,-786.88732910156,30.768054962158}},
            {id = 9, pos = {218.8422088623,-794.09161376953,30.764490127563}},
            {id = 10, pos = {215.91780090332,-801.59564208984,30.80283164978}}
        }
    }
}

cfg.multy_parking = {
    ["Maze Parking"] = { 
        slots = 2,
        location = {-84.267807006836,-821.44219970703,36.027992248535}
    }
}


return cfg


