# Getting Started

This section will guide you through setting up your development environment and getting the Bluetooth Terminal application up and running on your machine.

## Prerequisites

Before you begin, make sure you have the following installed:

*   **Flutter:** Follow the official Flutter installation guide for your operating system: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
*   **Dart SDK:** The Flutter installation includes the Dart SDK.
*   **VS Code (Recommended IDE):** Download and install Visual Studio Code: [https://code.visualstudio.com/](https://code.visualstudio.com/)
*   **Flutter and Dart Extensions for VS Code:** Install the official Flutter and Dart extensions from the VS Code marketplace.
*   **Android Studio or Xcode (for mobile development):** If you plan to develop for Android or iOS, you'll need to set up their respective development environments. Follow the Flutter setup guide for details.

## Setting up the Project

1.  **Clone the Repository:**
    If the project is hosted in a Git repository, clone it to your local machine using your preferred Git client or the command line:

    ```bash
    git clone <repository_url>
    ```

    Replace `<repository_url>` with the actual URL of the project's Git repository.

2.  **Open the Project in VS Code:**
    Open the cloned project folder in VS Code.

3.  **Get Dependencies:**
    Open a terminal in VS Code (Terminal > New Terminal) and run the following command to fetch the project's dependencies:

    ```bash
    flutter pub get
    ```

## Running the Application

You can run the application on a connected device (Android or iOS), an emulator/simulator, or as a desktop application (if supported).

1.  **Connect a Device or Start an Emulator:**
    Make sure you have a physical device connected to your computer or an emulator/simulator running.

2.  **Select a Device:**
    In the VS Code status bar (usually at the bottom right), select the target device you want to run the app on.

3.  **Run the App:**
    Open a terminal in VS Code and run the following command:

    ```bash
    flutter run
    ```

    Alternatively, you can use the "Run and Debug" view in VS Code (Ctrl+Shift+D or Cmd+Shift+D), select "Dart & Flutter" from the dropdown, and click the "Run and Debug" button.

This will build and launch the application on your selected device. You should now see the Bluetooth Terminal app running.

## Next Steps

Now that you have the application running, you can explore the codebase starting with the [Project Structure](project_structure.md) section to understand how the different parts of the application are organized.