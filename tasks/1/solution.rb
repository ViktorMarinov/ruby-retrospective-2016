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

MELTING_POINTS_CELSIUS = {
  'water' => 0,
  'ethanol' => -114,
  'gold' => 1_064,
  'silver' => 961.8,
  'copper' => 1_085
}

BOILING_POINTS_CELSIUS = {
  'water' => 100,
  'ethanol' => 78.37,
  'gold' => 2_700,
  'silver' => 2_162,
  'copper' => 2_567
}

def convert_between_temperature_units(degrees, from_unit, to_unit)
  if CONVERTER[from_unit].key?(to_unit)
    CONVERTER[from_unit][to_unit].call(degrees)
  else
    degrees_in_celsius = CONVERTER[from_unit]['C'].call(degrees)
    CONVERTER['C'][to_unit].call(degrees_in_celsius)
  end
end

def melting_point_of_substance(substance, unit)
  CONVERTER['C'][unit].call(MELTING_POINTS_CELSIUS[substance])
end

def boiling_point_of_substance(substance, unit)
  CONVERTER['C'][unit].call(BOILING_POINTS_CELSIUS[substance])
end