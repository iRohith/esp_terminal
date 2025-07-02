import 'dart:typed_data';

import 'package:esp_terminal/util/constants.dart';

/// Represents a data packet exchanged with a connected device.
///
/// Encapsulates a command, a floating-point value, and an identifier.
/// Provides methods for serialization to and deserialization from a byte buffer.
class DataPacket {
  /// The command byte of the packet.
  ///
  /// Indicates the type of data or action (e.g., sensor reading, control command).
  int cmd;

  /// The floating-point value associated with the command.
  ///
  /// Can represent a sensor reading, a setpoint, or any numerical data.
  double value;

  /// The identifier of the data packet.
  ///
  /// Used for sequencing, matching requests to responses, or identifying a data channel.
  int id;

  /// An optional field for additional, flexible data.
  dynamic extra;

  /// Constructs a [DataPacket] instance.
  ///
  /// [cmd]: The command byte (defaults to -1).
  /// [id]: The packet identifier (defaults to -1).
  /// [value]: The floating-point value (defaults to 0.0).
  /// [extra]: Optional additional data.
  DataPacket({this.cmd = -1, this.id = -1, this.value = 0, this.extra});

  /// Creates a new [DataPacket] instance by copying existing values
  /// and optionally overriding specific properties.
  ///
  /// Returns a new [DataPacket] instance with updated properties.
  DataPacket copyWith({int? cmd, double? value, int? id, dynamic extra}) {
    return DataPacket(
      cmd: cmd ?? this.cmd,
      value: value ?? this.value,
      id: id ?? this.id,
      extra: extra ?? this.extra,
    );
  }

  /// Converts this [DataPacket] instance into a [Uint8List] byte buffer.
  ///
  /// Serializes `cmd`, `value` (as 32-bit float), and `id` into a fixed-size
  /// byte array for transmission.
  ///
  /// [buffer]: Optional existing [Uint8List] to write into. If `null`, a new buffer of [PACKET_SIZE] is created.
  /// [offset]: Starting byte offset within the `buffer` (defaults to 0).
  /// [littleEndian]: Specifies byte order for the float value (defaults to big-endian).
  ///
  /// Returns the [Uint8List] buffer containing the serialized packet data.
  Uint8List toBuffer({
    Uint8List? buffer,
    int offset = 0,
    bool littleEndian = false,
  }) {
    // Create a new buffer if none is provided, with a size defined by PACKET_SIZE.
    buffer ??= Uint8List(PACKET_SIZE);
    // Create a ByteData view to easily manipulate bytes within the buffer.
    ByteData byteData = ByteData.view(buffer.buffer, offset);

    // Write the command byte at the first position (offset 0).
    byteData.setUint8(0, cmd);
    // Write the floating-point value at offset 1, converting it to a 32-bit float.
    // Endianness (byte order) is specified for correct interpretation.
    byteData.setFloat32(1, value, littleEndian ? Endian.little : Endian.big);
    // Write the packet ID byte at offset 5.
    byteData.setUint8(5, id);

    // Add padding bytes (0xFF) at offsets 6 and 7 if the buffer is large enough.
    // This ensures the packet always occupies a consistent size, which can be important
    // for fixed-length protocols or future expansion.
    if (buffer.length - offset >= 8) {
      byteData.setUint8(6, 0xFF);
      byteData.setUint8(7, 0xFF);
    }

    return buffer; // Return the buffer containing the serialized packet.
  }

  /// Populates this [DataPacket] instance from a byte buffer.
  ///
  /// Deserializes `cmd`, `value`, and `id` from a byte array received from a device.
  ///
  /// [buffer]: The [Uint8List] byte buffer containing the packet data.
  /// [offset]: Starting byte offset within the `buffer` (defaults to 0).
  /// [littleEndian]: Specifies byte order for the float value (defaults to big-endian).
  void fromBuffer(
    Uint8List buffer, {
    int offset = 0,
    bool littleEndian = false,
  }) {
    // Create a ByteData view to easily read different data types from the buffer.
    ByteData byteData = ByteData.view(buffer.buffer, offset);
    // Read the command byte from offset 0.
    cmd = byteData.getUint8(0);
    // Read the floating-point value from offset 1, respecting the specified endianness.
    value = byteData.getFloat32(1, littleEndian ? Endian.little : Endian.big);
    // Read the ID byte from offset 5.
    id = byteData.getUint8(5);
  }

  /// Creates a new [DataPacket] instance from a byte buffer.
  ///
  /// A convenient factory to create a [DataPacket] object directly from a received byte array.
  ///
  /// [buffer]: The [Uint8List] byte buffer containing the packet data.
  /// [offset]: Starting byte offset in the buffer (defaults to 0).
  /// [littleEndian]: Specifies the endianness of the floating-point value (defaults to big-endian).
  ///
  /// Returns a new [DataPacket] instance populated with data from the buffer.
  factory DataPacket.fromBuffer(
    Uint8List buffer, {
    int offset = 0,
    bool littleEndian = false,
  }) {
    // Create a new DataPacket instance and then populate its fields
    // by calling the `fromBuffer` method with the provided buffer and options.
    return DataPacket()
      ..fromBuffer(buffer, offset: offset, littleEndian: littleEndian);
  }

  @override
  /// Returns a human-readable string representation of the [DataPacket].
  ///
  /// Formats command, ID (in hex), and value (fixed to 3 decimal places) for debugging.
  String toString() {
    return "Id: 0x${id.toRadixString(16).toUpperCase()}; Cmd: 0x${cmd.toRadixString(16).toUpperCase()}; Value: ${value.toStringAsFixed(3)}";
  }

  /// Converts this [DataPacket] instance into a JSON-compatible map.
  ///
  /// Used for serializing the packet, typically for logging or saving.
  Map<String, dynamic> toJson() {
    return {'cmd': cmd, 'value': value, 'id': id};
  }

  /// Creates a [DataPacket] instance from a JSON map.
  ///
  /// Deserializes a [DataPacket] object from a JSON source, providing a default
  /// value for `value` if missing.
  ///
  /// [json]: A map containing the packet's data.
  factory DataPacket.fromJson(Map<String, dynamic> json) {
    return DataPacket(
      cmd: json['cmd'] as int, // Extract 'cmd' as an integer.
      // Extract 'value' as a double, providing a default of 0.0 if null.
      value: json['value']?.toDouble() ?? 0.0,
      id: json['id'] as int, // Extract 'id' as an integer.
    );
  }
}
