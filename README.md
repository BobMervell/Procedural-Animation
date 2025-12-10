# Procedural animation

Procedural Animation Addon ⚙️🎮 An addon for Godot 4.4 ( may work but untested for later versions) that introduces a suite of dedicated nodes designed to facilitate the creation of highly customizable procedural movements within the Godot Engine.
![robot movement](https://github.com/user-attachments/assets/acbd62a2-9462-43af-9b7b-72059f442403)

## Repository States
![Status: Unmanaged](https://img.shields.io/badge/status-unmanaged-gray)
![Status: Experimental](https://img.shields.io/badge/status-experimental-blue)

### **Experimental**
- The repository contains features or ideas that are in a testing phase.
- Not intended for production use, and stability is not guaranteed.

### **Unmanaged**
- The repository exists but has no active maintainers.
- No updates, support, or management of issues are expected.



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
   - Start with a `Node3D` node. This will serve as the base for your character.

2. **Attach Leg Nodes:**
   - Add four `ThreeSegmentLeg` nodes to your character. Ensure you are using `ThreeSegmentLeg` and not `ThreeSegmentLegClass`, which is an internal class used by the plugin.
   - Position the four `ThreeSegmentLeg` nodes at the corners of your character.

3. **Add Controller:**
   - Add a `RadialQuadripedController` node as a child to yourcharacter.

4. **Configure the Controller:**
   - In the `RadialQuadripedController`, specify the corresponding node for each leg and the body.
   - Customize the behavior settings within the controller to match your desired animation dynamics.

5. **Movement and Rotation:**
   - You can move and rotate the caracter in the editor with the procedural animation, to do that you need to use the export variables target_position_2D and target_rotation_y in the RadialQuadripedController

By following these steps, you can effectively integrate the Procedural Animation Addon into your Godot project, enabling dynamic and customizable procedural movements for your character.

## 📝 License:

This project is licensed under the MIT, you can use and modify freely, credit is not mandatory but really appreciated. 

## 🌟 Support:

❓ Need help? feel free to ask i will gladly help.





