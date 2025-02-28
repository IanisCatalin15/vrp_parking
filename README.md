Parking System for FiveM (vRP Framework)

🚧 Under Development 🚧

This project is currently in development. Some features may not be fully functional, and future updates are planned to improve stability and expand capabilities.

📌 About

This is a parking system for FiveM that extends the vRP framework. The system allows players to:

Park their vehicles in designated parking lots.

Retrieve their stored vehicles.

Purchase vehicles from a showroom.

Manage multiple parking slots.

Store vehicle data persistently.

The system is designed to integrate seamlessly with vRP, ensuring that vehicle data is properly stored and retrieved while maintaining customization and condition.

🛠 Features

✔️ Store and retrieve player-owned vehicles. ✔️ Persistent vehicle data (health, customization, fuel, and locked state). ✔️ Multi-slot parking system with assigned slots. ✔️ Showroom integration for vehicle purchases. ✔️ Supports multiple parking locations. ✔️ Parking slot management to prevent overwriting. ✔️ SQL-based parking slot database management. ✔️ vRP-compatible GUI menus for interaction.

📜 Installation

Requirements:

FiveM server

vRP Framework

MySQL Database

Steps:

Download the Files

Clone this repository or download the vrp_parking script.

Add to vRP Extensions

Place the server.lua file inside your resources/ directory.

Configure MySQL

Ensure your database is correctly set up to store parking slots.

Import the required SQL tables (see vRP/park table creation in the script).

Start the Resource

Add the following line to your server.cfg:

ensure vrp_parking

Restart the server.

🎮 Usage

Buying a Vehicle

Visit a showroom and purchase a vehicle.

The vehicle will be stored in the showroom garage.

Parking a Vehicle

Drive to a designated parking area.

Open the parking menu and select the option to park your vehicle.

Retrieving a Vehicle

Go to the parking lot where your vehicle is stored.

Open the menu and retrieve your vehicle.

Multi-Slot Parking

If a parking lot supports multiple slots, the system will find the first available space.

🔧 Configuration

You can customize parking areas and vehicle spawn locations inside the vrp_parking/cfg.lua file.

Define new parking locations.

Adjust vehicle spawn distances.

Modify showroom vehicle prices.

📌 Known Issues & Future Updates

🚧 Under Development 🚧

Some parking slot assignments might need refinement.

Showroom purchase integration is being improved.

Enhancing database performance for large-scale servers.

💬 Contributing

If you have suggestions, bug reports, or improvements, feel free to submit an issue or pull request!

📢 Contact

For support or inquiries, reach out via GitHub Issues or the FiveM development forums.

🎮 Enjoy the Parking System for vRP! 🚗
