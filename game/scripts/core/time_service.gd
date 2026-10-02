extends Node
## Real clock integration: day/night cycle and offline time.

var override_hour: float = -1.0   # for testing / screenshots


func hour() -> float:
	if override_hour >= 0.0:
		return override_hour
	var t := Time.get_datetime_dict_from_system()
	return float(t["hour"]) + float(t["minute"]) / 60.0


## "dawn" 05-06, "day" 06-17, "dusk" 17-20, "night" 20-05
func time_of_day() -> String:
	var h := hour()
	if h >= 5.0 and h < 6.5:
		return "dawn"
	if h >= 6.5 and h < 17.0:
		return "day"
	if h >= 17.0 and h < 20.0:
		return "dusk"
	return "night"


func is_night() -> bool:
	return time_of_day() == "night"


func is_weekend() -> bool:
	var wd: int = Time.get_datetime_dict_from_system()["weekday"]
	return wd == 0 or wd == 6


## Color tint for world layers based on the time of day (smoothly blended).
func world_tint() -> Color:
	var h := hour()
	var keys := [[0.0, Color(0.42, 0.45, 0.72)], [5.0, Color(0.48, 0.5, 0.78)], [6.0, Color(1.0, 0.82, 0.78)],
		[8.0, Color(1, 1, 1)], [16.5, Color(1, 1, 1)], [18.5, Color(1.0, 0.78, 0.62)], [20.0, Color(0.55, 0.52, 0.8)],
		[24.0, Color(0.42, 0.45, 0.72)]]
	for i in keys.size() - 1:
		var a: Array = keys[i]
		var b: Array = keys[i + 1]
		if h >= float(a[0]) and h <= float(b[0]):
			var t: float = (h - float(a[0])) / max(0.001, float(b[0]) - float(a[0]))
			return (a[1] as Color).lerp(b[1], t)
	return Color(1, 1, 1)


func unix_now() -> int:
	return int(Time.get_unix_time_from_system())
