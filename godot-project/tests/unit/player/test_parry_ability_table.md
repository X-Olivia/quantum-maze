| Test ID | Test Name | Test Description | Inputs | Expected Outcome | Pass/Fail | Date | Notes |
|---------|-----------|------------------|--------|------------------|-----------|------|-------|
| 1 | test_energy_consumption | test player comsumes correct amount of energy to parry | - Create new player instance - Create new parry_ability instance | - Energy does not decrease within perfect time - Energy decreases at correct rate - Player could not activate parry with no enough energy | PASS | 10/02/25 | |
| 2 | test_parry_photon | test parry the photon | - Create player instance - Create parry_ability instance - Create photon instance | - Photon should be reflected by perfect parry - The damage of photon should be decreases by an exact value | PASS | 10/02/25 | |
| 3 | test_parry_enemy | test parry the enemy | - Create player instance - Create parry_ability instance - Create enemy instance  | Enemy should be bounced back by perfect parry | PASS | 10/02/25 | |
