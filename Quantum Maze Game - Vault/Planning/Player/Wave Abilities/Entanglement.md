#### Passive Entanglement 
- Objects that are already entangled, without the player doing anything.

#### Active Entanglement 
- when a player uses the entanglement ability to manually connect items

All entangle-able objects within range will be highlighted.
The player can LCLICK on one of these to set it as the first object.
All entangle-able objects within range that can be entangled to the first object will then be highlighted.
The player can RCLICK on one of these to entangle the 2 objects.

Each possibility can entangle 2 objects, enabling chaining.

![[EntanglementPrototype.png]]

Generally speaking, entangling an output to an input will produce behaviour as expected if they were connected via wire, however for certain use cases we can specify entanglement-specific behaviour if we wish. 
  
#### Entanglement tables

##### Enemy

| Enemy entangled to.. | Entanglement                                                                                                                                                         |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Enemy                | Attacking one enemy will apply a 20% damage multiplier to the enemy not being attacked                                                                               |
| Player               | Enemy will follow player movements, player can make enemy activate an antiparticle detector. (Only available when enemy is low health -10% or less health remaining) |
| Switch               | (When lever toggled) Enemy switches into wave mode (at which point enemy will stop attacking and ignores/doesn’t follow player)                                      |
| Button               | Enemy gets electrocuted, takes -15% damage.                                                                                                                          |

##### Components 

| Item A          | Item B               | Entanglement                                                                               |
| --------------- | -------------------- | ------------------------------------------------------------------------------------------ |
| Button          | Switch               | Hitting button will toggle lever and toggling lever will simulate button press             |
| Button          | Button               | Pressing one button will simulate button press of the other button.                        |
| Solar Panel     | Particle Accelerator | Shooting the panel will activate the particle accelerator normally and provide speed boost |
| Moving Platform | Switch               | Toggle direction of platform                                                               |
