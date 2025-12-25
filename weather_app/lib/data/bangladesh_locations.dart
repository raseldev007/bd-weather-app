class BdLocation {
  final String name;
  final double lat;
  final double lon;
  const BdLocation(this.name, this.lat, this.lon);
}

const List<BdLocation> bangladeshLocations = [
  BdLocation("Dhaka", 23.8103, 90.4125),
  BdLocation("Chattogram", 22.3569, 91.7832),
  BdLocation("Khulna", 22.8456, 89.5403),
  BdLocation("Rajshahi", 24.3745, 88.6042),
  BdLocation("Sylhet", 24.8949, 91.8687),
  BdLocation("Barishal", 22.7010, 90.3535),
  BdLocation("Rangpur", 25.7439, 89.2752),
  BdLocation("Mymensingh", 24.7471, 90.4203),
  BdLocation("Comilla", 23.4607, 91.1809),
  BdLocation("Narayanganj", 23.6238, 90.5000),
  BdLocation("Gazipur", 23.9999, 90.4203),
];
