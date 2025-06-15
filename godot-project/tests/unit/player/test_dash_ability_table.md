| Test ID | Test Name | Test Description | Inputs | Expected Outcome | Pass/Fail | Date | Notes |
|---------|-----------|------------------|--------|------------------|-----------|------|-------|
| 1 | test_start_dash | test start_dash method in dash_ability | - Create dash_ability - Call start_dash() method | The parent of dash_ability(a player in this case) starts dash | PASS | 18/02/25 | |
| 2 | test_stop_dash | test stop_dash method in dash_ability | - Create dash_ability - Call start_dash() method - Call stop_dash() method | The parent of dash_ability(a player in this case) stops dash | PASS | 18/02/25 | |
| 3 | test_timer_timeout | test all timers timeout methods in dash_ability | - Create dash_ability - Call start_dash() method - Call on_timer_timeout() method | - The parent of dash_ability(a player in this case) stops dash - 'can_dash' variable in dash_ability should be 'true' | PASS | 18/02/25 | |
| 4 | test_collided | test the collision to walls | - Create dash_ability - Create walls - make player collide with the wall | the collision method should return false | PASS | 18/02/25 | |
