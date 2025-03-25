# Procedural animation

Procedural Animation Addon ⚙️🎮 A Godot addon that introduces a suite of dedicated nodes designed to facilitate the creation of highly customizable procedural movements within the Godot Engine.
![robot movement](https://github.com/user-attachments/assets/acbd62a2-9462-43af-9b7b-72059f442403)

# ✨ Features:

✔️ Advanced Leg Configuration – Customize leg segments with precise control over bones lengths and positions allowing for configurable legs structures.

### Example of legs structures:
![Image](https://github.com/user-attachments/assets/d3ce982e-b84b-4a66-bf46-49107394cf63)
![Image](https://github.com/user-attachments/assets/dee9d038-c515-40ca-8adc-d0af70c6f595)


✔️ Customizable Leg Behavior – Define leg behavior with parameters like rest distance, extension speed, and rotation amplitude, 
path followed by the foot while returning to the leg's base position tailoring movements to specific needs.
### Example of legs behavior:
![classic_leg](https://github.com/user-attachments/assets/8429c5b8-2d32-4442-b2e8-430fa53f3e71)
![excentric-leg](https://github.com/user-attachments/assets/a78b27c6-3312-4db4-89a0-b1235f0fc74d)

✔️ Dynamic Ground Adaptation – The body and the legs adapts to the ground's angle and height at a configurable speed, ensuring smooth and realistic motion over uneven terrain.

✔️ Second Order Controllers – Integrate second-order systems for both movement and rotation, providing fine-tuned control over animation dynamics.

✔️ Real-Time Simulation – Activate walk cycle simulations with adjustable targets and rotation angles, enabling real-time testing and iteration of animations.

✔️ Example Scenes – Includes example scenes to help you get started quickly and understand the addon's capabilities.

# 📦 Installation:

**This addon needs the SecondOrderDynamics to work.**

1. **Download the Addon:** Clone or download the repository from GitHub.
2. **Move the Folder:** Place the ProceduralAnimation folder inside your "res://addons/" directory.
3. **Enable the Plugin:**

    Open Godot Editor.
   
    Go to Project > Project Settings > Plugins.
   
    Enable ProceduralAnimation Addon.

**Note:** You only need to place the ProceduralAnimation folder in "res://addons/" in your godot app.
4. Repeat the same steps for the SecondOrderDynamics addon (also present on my github account).


# 🛠️ Usage Guide:
To utilize the Procedural Animation Addon, follow these steps to set up your character with procedural movements:

1. **Character Setup:**
   - Start with a `CharacterBody3D` node. This will serve as the base for your character.

2. **Attach Leg Nodes:**
   - Add four `ThreeSegmentLeg` nodes to your `CharacterBody3D`. Ensure you are using `ThreeSegmentLeg` and not `ThreeSegmentLegClass`, which is an internal class used by the plugin.
   - Position the four `ThreeSegmentLeg` nodes at the corners of your `CharacterBody3D`.

3. **Add Controller:**
   - Add a `RadialQuadripedController` node as a sibling to your `CharacterBody3D` (i.e., under the same parent node).

4. **Configure the Controller:**
   - In the `RadialQuadripedController`, specify the corresponding node for each leg and the body.
   - Customize the behavior settings within the controller to match your desired animation dynamics.

5. **Movement and Rotation:**
   - To move or rotate the `CharacterBody3D` in the editor, manipulate the `RadialQuadripedController`. Your character will follow the controller's movements.
   - Note: For movements along the Z-axis, directly adjust the `CharacterBody3D` node.

By following these steps, you can effectively integrate the Procedural Animation Addon into your Godot project, enabling dynamic and customizable procedural movements for your character.

## 📝 License:

This project is licensed under the CC BY-NC 4.0, you can use and modify it except for commercial uses credit is needed. 

## 🌟 Support:

❓ Need help? feel free to ask i will gladly help.





