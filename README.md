# Digital Alarm Clock

## Feature

* [X] Timer Inturepter (Clock)

  * [X] Change Clock (RAM) for SS change
  * [X] Change Clock Display (LCD) for SS change
  * [X] Check Alarm (HH==HH & MM==MM) for MM change
* [X] LCD Display

  * [X] Clock Display
  * [X] Alarm Input Display
* [X] Keypad Input

  * [X] Go to Alarm Insert mode (C)
  * [X] Input Alarm Time (HH MM)
  * [X] Multiple Alarm Input
* [X] Snooze Feature
* [X] Buzzer Feature
* [X] Use Code to turn off Alarm (Match with Code saved in RAM )
* [ ] LED Random Pattern

  * [X] Generate Random Pattern
  * [X] Turn off Alarm with given Pattern (Save Code in RAM)
  * [ ] Turn on LED based on CODE PATTERN

## How to use:

* [ ] Keypad - `C`  to goto setup mode.
  * [ ] Keypad -  `0` -> to Show Alarms << Input Index of the Alarm
  * [X] Keypad -  `1` -> to Set Alarms
    * [X] Input Index of the Alarm
    * [X] Input Time: `HH MM	`	=> Keypad - `=`	 -> To go next
    * [X] Snooze Time 5min(1) / 10min(2) / 15min(3)  -> Input : 1/2/3
  * [ ] Keypad -  `2` -> to Del Alarms << Input Index of the Alarm
* [X] Stop/Snooze Alarm
  * [X] Stop
    * [X] Write Code Number
  * [X] Snooze: ->  Keypad - `+`

## Challenges

* Performing Multiple tasks parallel.
* Wisely use A, B. As multiple modules like LCD, Keypad, Alarm use A ans B , push pop was needed.
* Timer Calculation

$$
f = 11.0592Hz
$$

$$
T = 12/f = 1.085us
$$

$$
t = 1s
$$

$$
MC = \frac{t}{T} = 921,658.986
$$

$$
MC = 65536 \times 14.06
$$

$$
MC = (FFFF) \times (E)
$$

$$
Timer 0 = 0000H
$$

$$
TMOD = 01H
$$

After every 0E times of full Timer_0 rotation SS will Increment and other as so.

$$
Clock = HH-MM-SS-0E
$$

$$


$$

$$


$$

$$


$$
