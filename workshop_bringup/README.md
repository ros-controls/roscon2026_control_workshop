
## Async Controllers Hands-On

### The Synchronous Problem
```bash
$ ros2 launch workshop_bringup rrbot.launch.py
```

```bash
$ ros2 control list_controllers
sleepy_controller           workshop_controllers/SleepyController                active
forward_position_controller forward_command_controller/ForwardCommandController  active
position_controller         passthrough_controller/PassthroughController         active
joint2_position_controller  passthrough_controller/PassthroughController         active
joint1_position_controller  passthrough_controller/PassthroughController         active
joint_state_broadcaster     joint_state_broadcaster/JointStateBroadcaster        active
```

```bash
$ ros2 control view_controller_chains --save
$ qpdfview controller_diagram.pdf
```


```bash
$ ros2 run plotjuggler plotjuggler --layout src/roscon2026_control_workshop/workshop_bringup/pj.xml
```

```bash
$ ros2 service call /sleepy_controller/set_slow_control_mode example_interfaces/srv/SetBool "data: true"
```

```bash
$ ros2 run swri_console swri_console
```

```
[ros2_control_node-1] [WARN] [1787659624.612185875] [controller_manager]: Overrun might occur, Total time : 433260.452 us (Expected < 100000.000 us) --> Read time : 24.744 us, Update time : 433135.775 us, Write time : 99.933 us
[ros2_control_node-1] [WARN] [1787659624.612206667] [controller_manager]: Overrun detected! The controller manager missed its desired rate of 10 Hz. The loop took 433.306503 ms (missed cycles : 5).
```

### Async Saves You
```bash
# our custom sleepy controller
sleepy_controller:
  ros__parameters:
    type: workshop_controllers/SleepyController
    max_sleep_time: 0.5
    is_async: true
```

```bash
# ros2 control list_controllers -v
sleepy_controller           workshop_controllers/SleepyController                active
        update_rate: 10 Hz
        is_async: True
        claimed interfaces:
        required command interfaces:
        required state interfaces:
        chained to interfaces:
        exported reference interfaces:
        exported state interfaces:
                max_sleep_time
```

```bash
[ros2_control_node-1] [WARN] [1787660029.598285066] [sleepy_controller]: The controller missed 662 update cycles out of 2750 total triggers.
```

## Async Hardware Hands-On

* Increase processing time
  ```xml
    <hardware>
        <plugin>workshop_hardware/RRBotSystemPositionOnlyHardware</plugin>
        ...
        <param name="write_processing_time_ms">75</param>
    </hardware>
  ```

* See results in plotjuggler and console log
* Configure async and scheduling_policy
  ```xml
      <ros2_control name="${name}" type="system"
                is_async="true" rw_rate="5">
        <properties>
          <async thread_priority="60"
                  scheduling_policy="detached"
                  print_warnings="true"/>
        </properties>
      </ros2_control>
  ```
* Restart, and see if it worked
  ```bash
  $ ros2 control list_hardware_components
  Hardware Component 1
          name: RRBot
          type: system
          plugin name: workshop_hardware/RRBotSystemPositionOnlyHardware
          state: id=3 label=active
          read/write rate: 5 Hz
          is_async: True
          command interfaces
                  joint2/position [available] [claimed]
                  joint1/position [available] [claimed]
  ```
  or with `ros2 run rqt_controller_manager rqt_controller_manager`
