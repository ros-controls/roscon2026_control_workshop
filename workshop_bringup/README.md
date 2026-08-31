
# Async Hands-On

## The Synchronous Problem
Starting a simple example
```bash
$ ros2 launch workshop_bringup rrbot.launch.py
```
and analyze the setup. All controllers can be listed with
```bash
$ ros2 control list_controllers
sleepy_controller           workshop_controllers/SleepyController                active
forward_position_controller forward_command_controller/ForwardCommandController  active
position_controller         passthrough_controller/PassthroughController         active
joint2_position_controller  passthrough_controller/PassthroughController         active
joint1_position_controller  passthrough_controller/PassthroughController         active
joint_state_broadcaster     joint_state_broadcaster/JointStateBroadcaster        active
```
or with `ros2 run rqt_controller_manager rqt_controller_manager`

Have a look at the controller chain: The sleepy_controller is not part of the chain but still effecting the controller_manager update as we will see later.
```bash
$ ros2 control view_controller_chains --save && qpdfview controller_diagram.pdf
```

Open Plotjuggler and have a look at the statistics topics
```bash
$ ros2 run plotjuggler plotjuggler --layout src/roscon2026_control_workshop/workshop_bringup/pj.xml
```

Now we increase the average update duration of the sleepy_controller
```bash
$ ros2 service call /sleepy_controller/set_slow_control_mode example_interfaces/srv/SetBool "data: true"
```
and we see in the console log
```bash
$ ros2 run swri_console swri_console
```
that overruns were detected:
```
[ros2_control_node-1] [WARN] [1787659624.612185875] [controller_manager]: Overrun might occur, Total time : 433260.452 us (Expected < 100000.000 us) --> Read time : 24.744 us, Update time : 433135.775 us, Write time : 99.933 us
[ros2_control_node-1] [WARN] [1787659624.612206667] [controller_manager]: Overrun detected! The controller manager missed its desired rate of 10 Hz. The loop took 433.306503 ms (missed cycles : 5).
```

We can now configure the controller to be async

```yaml
sleepy_controller:
  ros__parameters:
    type: workshop_controllers/SleepyController
    max_sleep_time: 0.5
    is_async: true
```

Restart and see if the setting worked by having a look at the `is_async` parameter in CLI

```bash
$ ros2 control list_controllers -v
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

or with `ros2 run rqt_controller_manager rqt_controller_manager`.

You still will see warnings of overruns, but this won't effect the controller_manager update cycle (see Plotjuggler)

```bash
[ros2_control_node-1] [WARN] [1787660029.598285066] [sleepy_controller]: The controller missed 662 update cycles out of 2750 total triggers.
```

## Async Hardware Hands-On

Increase the processing time by changing the xml to
```xml
<hardware>
  <plugin>workshop_hardware/RRBotSystemPositionOnlyHardware</plugin>
  ...
  <param name="write_processing_time_ms">75</param>
</hardware>
```

See results in plotjuggler and console log, it now will also break the RT cycle. Now, configure the hardware to be async and choose a scheduling_policy
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
Restart the demo, and see if it worked
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
or with `ros2 run rqt_controller_manager rqt_controller_manager`.

Overruns now should have disappeared.
