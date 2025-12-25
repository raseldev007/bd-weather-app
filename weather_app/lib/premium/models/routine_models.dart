import 'package:flutter/material.dart';
import 'guidance_models.dart';

enum CommuteMode { walk, rickshaw, bike, car, bus }
enum WorkIntensity { low, medium, high }

class GeneralRoutine {
  final TimeOfDay? studyTime;
  final TimeOfDay? focusTime;
  final TimeOfDay? returnTime;
  final CommuteMode commuteMode;

  const GeneralRoutine({
    this.studyTime,
    this.focusTime,
    this.returnTime,
    this.commuteMode = CommuteMode.walk,
  });
}



class RoutineBundle {
  final OutcomeProfileId profile;
  final GeneralRoutine? general;

  const RoutineBundle({
    required this.profile,
    this.general,
  });
}
