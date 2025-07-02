// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

/// Command byte for sending an ON signal.
const ON_SEND = 0x11;

/// Command byte for sending an OFF signal.
const OFF_SEND = 0x12;

/// Command byte for sending a MODE change signal.
const MODE_SEND = 0x13;

/// Command byte for sending an UP signal.
const UP_SEND = 0x14;

/// Command byte for sending a DOWN signal.
const DOWN_SEND = 0x15;

/// Command byte for sending a floating-point value.
const FLOAT_SEND = 0x00;

/// Command byte for sending a message string.
const MSG_SEND = 0x05;

/// Command byte for receiving a message string.
const MSG_RECV = 0x05;

/// Command byte for sending a file.
const FILE_SEND = 0x06;

/// Command byte for sending a password for validation.
const PASSWORD_SEND = 0x07;

/// Command byte for sending a ping request.
const PING = 0x30;

/// Command byte for receiving a floating-point value.
const FLOAT_RECV = 0x08;

/// Command byte indicating a valid password response.
const PASSWORD_VALID = 0x07;

/// Command byte indicating an invalid password response.
const PASSWORD_INVALID = 0x09;

/// The maximum number of lines to retain in the application logs.
const MAX_LOG_LINES = 100;

/// The maximum allowed height for a height constrained panel.
const MAX_PANEL_HEIGHT = 250;

/// The standard size of a data packet in bytes.
const PACKET_SIZE = 8;

/// A predefined palette of colors used for charting and visualization.
const List<Color> COLORS_PALETTE = [
  Colors.red,
  Colors.blue,
  Colors.green,
  Colors.yellow,
  Colors.orange,
  Colors.purple,
  Colors.pink,
  Colors.brown,
  Colors.grey,
];
