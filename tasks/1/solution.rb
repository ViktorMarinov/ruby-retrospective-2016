CONVERTER = {
  'C' => {
    'C' => -> (c) { c },
    'F' => -> (c) { (c * 9.0 / 5) + 32 },
    'K' => -> (c) { c + 273.15 }
  },
  'F' => {
    'C' => -> (f) { (f - 32) * 5.0 / 9 }
  },
  'K' => {
    'C' => -> (k) { k - 273.15 }
  }
}

SUBSTANCES = {
  'water'   => {melting_point: 0,     boiling_point: 100  },
  'ethanol' => {melting_point: -114,  boiling_point: 78.37},
  'gold'    => {melting_point: 1_064, boiling_point: 2_700},
  'silver'  => {melting_point: 961.8, boiling_point: 2_162},
  'copper'  => {melting_point: 1_085, boiling_point: 2_567}
}

def convert_between_temperature_units(degrees, from_unit, to_unit)
  degrees_in_celsius = CONVERTER[from_unit]['C'].call(degrees)
  CONVERTER['C'][to_unit].call(degrees_in_celsius)
end

def melting_point_of_substance(substance, unit)
  CONVERTER['C'][unit].call(SUBSTANCES[substance][:melting_point])
end

def boiling_point_of_substance(substance, unit)
  CONVERTER['C'][unit].call(SUBSTANCES[substance][:boiling_point])
end