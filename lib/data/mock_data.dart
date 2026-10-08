import 'package:flutter/material.dart';

import '../models/equipment.dart';
import '../models/rental.dart';

const mockEquipment = <Equipment>[
  Equipment(
    id: 'EQ-1001',
    name: 'Canon EOS R50 Camera',
    category: 'Cameras',
    description: 'Mirrorless camera kit with lens, battery, and carrying case.',
    availableUnits: 4,
    totalUnits: 8,
    icon: Icons.photo_camera_outlined,
  ),
  Equipment(
    id: 'EQ-1002',
    name: 'DJI RS 3 Mini Gimbal',
    category: 'Stabilizers',
    description: 'Lightweight three-axis stabilizer for supported cameras.',
    availableUnits: 2,
    totalUnits: 5,
    icon: Icons.videocam_outlined,
  ),
  Equipment(
    id: 'EQ-1003',
    name: 'Zoom H6 Audio Recorder',
    category: 'Audio',
    description: 'Portable six-track recorder with microphones and case.',
    availableUnits: 0,
    totalUnits: 6,
    icon: Icons.mic_none_outlined,
  ),
  Equipment(
    id: 'EQ-1004',
    name: 'Manfrotto Tripod',
    category: 'Tripods',
    description: 'Adjustable video tripod with fluid head and carrying bag.',
    availableUnits: 7,
    totalUnits: 10,
    icon: Icons.change_history_outlined,
  ),
  Equipment(
    id: 'EQ-1005',
    name: 'LED Lighting Kit',
    category: 'Lighting',
    description: 'Two dimmable LED panels, stands, batteries, and case.',
    availableUnits: 3,
    totalUnits: 7,
    icon: Icons.lightbulb_outline,
  ),
  Equipment(
    id: 'EQ-1006',
    name: 'Dell Precision Laptop',
    category: 'Computers',
    description: 'Mobile workstation with charger and protective sleeve.',
    availableUnits: 5,
    totalUnits: 12,
    icon: Icons.laptop_mac_outlined,
  ),
];

List<Rental> get mockRentals => [
  Rental(
    id: 'R-24018',
    equipmentName: 'Canon EOS R50 Camera',
    assetTag: 'CAM-042',
    status: RentalStatus.checkedOut,
    dueDate: DateTime.now().add(const Duration(days: 5, hours: 2)),
  ),
  Rental(
    id: 'R-24019',
    equipmentName: 'LED Lighting Kit',
    assetTag: 'LGT-017',
    status: RentalStatus.checkedOut,
    dueDate: DateTime.now().add(const Duration(days: 11, hours: 4)),
  ),
  Rental(
    id: 'RS-9031',
    equipmentName: 'Dell Precision Laptop',
    assetTag: 'Assigned at pickup',
    status: RentalStatus.reserved,
    pickupDeadline: DateTime.now().add(const Duration(hours: 19)),
  ),
];
