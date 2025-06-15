# Floor Button Test Cases

| Test ID | Test Name | Test Description | Inputs | Expected Outcome | Pass/Fail | Date | Notes |
|---------|-----------|------------------|--------|------------------|-----------|------|-------|
| 1 | test_initial_state | Test if button starts in unpressed state with unpowered wire | - Create floor button<br>- Create wire<br>- Add wire to button's wires array | - Wire is not powered<br>- Button has default appearance | PASS | 03/05/25 | |
| 2 | test_button_press_and_release | Test complete button interaction cycle with player | - Create button and wire<br>- Position particle mode player over button<br>- Move player away | - Wire powers when player overlaps<br>- Button changes color to dark red<br>- Wire unpowers when player exits<br>- Button returns to default color | PASS | 03/05/25 | |
| 3 | test_wave_mode_player | Test that button ignores players in wave mode | - Create button and wire<br>- Set player to wave mode<br>- Position player over button | - Wire remains unpowered<br>- Button appearance unchanged | PASS | 03/05/25 | |
| 4 | test_non_player_collision | Test that button ignores non-player objects | - Create button and wire<br>- Create object not in Player group<br>- Position object over button | - Wire remains unpowered<br>- Button appearance unchanged | PASS | 03/05/25 | |
| 5 | test_multiple_wires | Test button controlling multiple wires | - Create button<br>- Create multiple wires<br>- Position player over button<br>- Move player away | - All wires power simultaneously<br>- All wires unpower simultaneously | PASS | 03/05/25 | |
| 6 | test_multiple_overlapping_bodies | Test button behavior with multiple players | - Position first player over button<br>- Add second player over button<br>- Remove first player<br>- Remove second player | - Button powers with first player<br>- Stays powered when second player added<br>- Remains powered when first player leaves<br>- Unpowers when all players leave | PASS | 03/05/25 | |
