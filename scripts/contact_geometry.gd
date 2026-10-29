class_name OrbitContactGeometry
extends RefCounted
## Shared by visible fly-bys and port availability; units are illustrated world pixels.
const PLANET_COUNT = 3
const PLANET_START_X = -150.0
const PLANET_SPACING = 480.0
const BASE_SPEED = 0.7
const SPEED_STEP = 0.25
const WRAP_OFFSET = 500.0
const WRAP_WIDTH = 1500.0
const APPROACH_MIN_X = -70.0
const APPROACH_MAX_X = 350.0

static func planet_x(index: int, time: float) -> float:
	return fposmod(PLANET_START_X+index*PLANET_SPACING+time*(BASE_SPEED+index*SPEED_STEP)+WRAP_OFFSET,WRAP_WIDTH)-WRAP_OFFSET
