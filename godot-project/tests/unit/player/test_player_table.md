| Test ID | Test Name | Test Description | Inputs | Expected Outcome | Pass/Fail | Date | Notes |
|---------|-----------|------------------|--------|------------------|-----------|------|-------|
| 1 | test_initial_health | test player starts with correct health values | - Create new player instance | - Health equals max_health (100.0)<br>- Max health equals 100.0 | PASS | 03/02/25 | |
| 2 | test_damage_system | test damage calculation works correctly | - Create player<br>- Apply 20.0 damage | Health decreases by exactly 20.0 | PASS | 03/02/25 | |
| 3 | test_damage_clamp | test health doesn't go below 0 | - Create player<br>- Apply 150.0 damage | Health does not go below 0 | PASS | 03/02/25 | |
| 4 | test_mode_switching | test mode transitions between Particle and Wave | - Press toggle mode in Particle mode<br>- Press toggle mode in Wave mode | - Player manager's set_to_possibility called + mode changes to wave<br>- Player manager's set_to_particle called + mode changes to particle | PASS | 03/02/25 | |
| 5 | test_movement_speed | test player speed limit | Set velocity to max_speed | Velocity length equals max_speed | PASS | 03/02/25 | |
| 6 | test_movement_direction | test directional movement including diagonal | - Press right<br>- Press right + up | - Moving right: x > 0, y = 0<br>- Moving diagonal: normalized movement vector | PASS | 03/02/25 | |
| 7 | test_kill_calls_manager | test kill() calls manager correctly | Call kill() on player | Manager's kill method called with correct player instance | PASS | 03/02/25 | |
| 8 | test_wave_mode_radius | test wave mode radius expansion | - Set mode to wave<br>- Process physics for 2.0s | Wave radius equals 80.0 (spread_speed * time) | PASS | 03/02/25 | |
