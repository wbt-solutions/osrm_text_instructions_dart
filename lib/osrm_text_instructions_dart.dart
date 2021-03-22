library osrm_text_instructions_dart;

import 'package:flutter/widgets.dart';
import 'package:osrm_dart_sdk/api.dart';

import 'languages.dart';

Map<String, dynamic> instructions = languages['instructions'];
Map<String, dynamic> grammars = languages['grammars'];
Map<String, dynamic> abbreviations = languages['abbreviations'];

String version = "v5";

String capitalizeFirstLetter(String language, String string) {
  return "${string[0].toUpperCase()}${string.substring(1)}";
}

String ordinalize(String language, int number) {
  // Transform numbers to their translated ordinalized value
  if (language == null) throw ('No language code provided');

  return instructions[language][version]["constants"]["ordinalize"]
          [number.toString()] ??
      '';
}

String directionFromDegree(String language, int degree) {
  // Transform degrees to their translated compass direction
  if (language == null) throw ('No language code provided');
  if (degree == null && degree != 0) {
    // step had no bearing_after degree, ignoring
    return '';
  } else if (degree >= 0 && degree <= 20) {
    return instructions[language][version]["constants"]["direction"]["north"];
  } else if (degree > 20 && degree < 70) {
    return instructions[language][version]["constants"]["direction"]
        ["northeast"];
  } else if (degree >= 70 && degree <= 110) {
    return instructions[language][version]["constants"]["direction"]["east"];
  } else if (degree > 110 && degree < 160) {
    return instructions[language][version]["constants"]["direction"]
        ["southeast"];
  } else if (degree >= 160 && degree <= 200) {
    return instructions[language][version]["constants"]["direction"]["south"];
  } else if (degree > 200 && degree < 250) {
    return instructions[language][version]["constants"]["direction"]
        ["southwest"];
  } else if (degree >= 250 && degree <= 290) {
    return instructions[language][version]["constants"]["direction"]["west"];
  } else if (degree > 290 && degree < 340) {
    return instructions[language][version]["constants"]["direction"]
        ["northwest"];
  } else if (degree >= 340 && degree <= 360) {
    return instructions[language][version]["constants"]["direction"]["north"];
  } else {
    throw ('Degree $degree invalid');
  }
}

String laneConfig(RouteStep step) {
  // Reduce any lane combination down to a contracted lane diagram

  List<String> config = [];
  bool currentLaneValidity;

  step.intersections[0].lanes.forEach((lane) {
    if (currentLaneValidity == null || currentLaneValidity != lane.valid) {
      if (lane.valid) {
        config.add('o');
      } else {
        config.add('x');
      }
      currentLaneValidity = lane.valid;
    }
  });

  return config.join('');
}

String getWayName(String language, RouteStep step, Options options) {
  List<String> classes = options != null ? options.classes ?? [] : [];
  if (language == null) throw ('No language code provided');
  if (!(classes is List)) throw ('classes must be an Array or undefined');

  String wayName;
  String name = step.name ?? '';
  String ref = (step.ref ?? '').split(';')[0];

  // Remove hacks from Mapbox Directions mixing ref into name
  if (name == step.ref) {
    // if both are the same we assume that there used to be an empty name, with the ref being filled in for it
    // we only need to retain the ref then
    name = '';
  }
  name = name.replaceAll(' (${step.ref})', '');

  // In attempt to avoid using the highway name of a way,
  // check and see if the step has a class which should signal
  // the ref should be used instead of the name.
  bool wayMotorway = classes.indexOf('motorway') != -1;

  if (name.isNotEmpty && ref.isNotEmpty && name != ref && !wayMotorway) {
    String phrase = instructions[language][version]["phrase"]['name and ref'] ??
        instructions['en'][version]["phrase"]['name and ref'];
    wayName = tokenize(
      language,
      phrase,
      {
        'name': name,
        'ref': ref,
      },
      options,
    );
  } else if (name != null &&
      ref != null &&
      wayMotorway &&
      RegExp(r"(/\d/)").hasMatch(ref)) {
    wayName =
        options?.formatToken != null ? options.formatToken('ref', ref) : ref;
  } else if (name == null && ref != null) {
    wayName =
        options?.formatToken != null ? options.formatToken('ref', ref) : ref;
  } else {
    wayName =
        options?.formatToken != null ? options.formatToken('name', name) : name;
  }

  return wayName;
}

/// Formulate a localized text instruction from a step.
///
/// @param  {string} language           Language code.
/// @param  {object} step               Step including maneuver property.
/// @param  {object} opts               Additional options.
/// @param  {string} opts.legIndex      Index of leg in the route.
/// @param  {string} opts.legCount      Total number of legs in the route.
/// @param  {array}  opts.classes       List of road classes.
/// @param  {string} opts.waypointName  Name of waypoint for arrival instruction.
///
/// @return {string} Localized text instruction.
String compile({
  @required String language,
  @required RouteStep step,
  Options opts,
}) {
  if (language == null) throw ('No language code provided');
  if (!languages['supportedCodes'].contains(language))
    throw ('language code ' + language + ' not loaded');
  if (step.maneuver == null) throw ('No step maneuver provided');
  var options = opts ?? Options();

  String type = step.maneuver.type;
  String modifier = step.maneuver.modifier;
  String mode = step.mode;
// driving_side will only be defined in OSRM 5.14+
  RouteStepDrivingSideEnum side = step.drivingSide;

  if (type == null) {
    throw ('Missing step maneuver type');
  }
  if (type != 'depart' && type != 'arrive' && modifier == null) {
    throw ('Missing step maneuver modifier');
  }

  if (instructions[language][version][type] == null) {
    // Log for debugging
    print('Encountered unknown instruction type: $type');
    // OSRM specification assumes turn types can be added without
    // major version changes. Unknown types are to be treated as
    // type `turn` by clients
    type = 'turn';
  }

  // Use special instructions if available, otherwise `defaultinstruction`
  Map<String, dynamic> instructionObject;
  if (instructions[language][version]["modes"][mode] != null) {
    instructionObject = instructions[language][version]["modes"][mode];
  } else {
    // omit side from off ramp if same as driving_side
    // note: side will be undefined if the input is from OSRM <5.14
    // but the condition should still evaluate properly regardless
    bool omitSide =
        type == 'off ramp' && modifier.indexOf(side.toString()) >= 0;
    if (instructions[language][version][type][modifier] != null && !omitSide) {
      instructionObject = instructions[language][version][type][modifier];
    } else {
      instructionObject = instructions[language][version][type]["default"];
    }
  }

// Special case handling
  String laneInstruction;
  switch (type) {
    case 'use lane':
      laneInstruction = instructions[language][version]["constants"]["lanes"]
          [laneConfig(step)];
      if (laneInstruction == null) {
        // If the lane combination is not found, default to continue straight
        instructionObject =
            instructions[language][version]['use lane']["no_lanes"];
      }
      break;
    case 'rotary':
    case 'roundabout':
      if (step.rotaryName != null &&
          step.maneuver.exit != null &&
          instructionObject["name_exit"] != null) {
        instructionObject = instructionObject["name_exit"];
      } else if (step.rotaryName != null && instructionObject["name"] != null) {
        instructionObject = instructionObject["name"];
      } else if (step.maneuver.exit != null &&
          instructionObject["exit"] != null) {
        instructionObject = instructionObject["exit"];
      } else {
        instructionObject = instructionObject["default"];
      }
      break;
    default:
    // NOOP, since no special logic for that type
  }

  // Decide way_name with special handling for name and ref
  String wayName = getWayName(language, step, options);

  // Decide which instruction string to use
  // In order of precedence:
  //   - exit + destination signage
  //   - destination signage
  //   - exit signage
  //   - junction name
  //   - road name
  //   - waypoint name (for arrive maneuver)
  //   - default
  String instruction;
  if (step.destinations != null &&
      step.exits &&
      instructionObject["exit_destination"] != null) {
    instruction = instructionObject["exit_destination"];
  } else if (step.destinations != null &&
      instructionObject["destination"] != null) {
    instruction = instructionObject["destination"];
  } else if (step.exits != null && instructionObject["exit"] != null) {
    instruction = instructionObject["exit"];
    //} else if (/*step.junction_name &&*/ instructionObject["junction_name"] != null) {
    //  instruction = instructionObject["junction_name"];
  } else if (wayName != null && instructionObject["name"] != null) {
    instruction = instructionObject["name"];
  } else if (options.waypointName != null &&
      instructionObject["named"] != null) {
    instruction = instructionObject["named"];
  } else {
    instruction = instructionObject["default"];
  }

  List<String> destinations = step.destinations?.toString()?.split(': ');
  String destinationRef =
      destinations != null ? destinations[0].split(',')[0] : null;
  String destination =
      destinations != null ? destinations[1]?.split(',')[0] : null;
  String firstDestination;
  if (destination != null && destinationRef != null) {
    firstDestination = '$destinationRef: $destination';
  } else {
    firstDestination = destinationRef ?? destination ?? '';
  }

  String nthWaypoint = options.legIndex != null &&
          options.legIndex >= 0 &&
          options.legIndex != options.legCount - 1
      ? ordinalize(language, options.legIndex + 1)
      : '';

// Replace tokens
// NOOP if they don't exist
  Map<String, String> replaceTokens = {
    'way_name': wayName,
    'destination': firstDestination,
    'exit': (step.exits?.toString() ?? '').split(';')[0],
    'exit_number': ordinalize(language, step.maneuver.exit ?? 1),
    'rotary_name': step.rotaryName,
    'lane_instruction': laneInstruction,
    'modifier': instructions[language][version]["constants"]["modifier"]
        [modifier],
    'direction': directionFromDegree(language, step.maneuver.bearingAfter),
    'nth': nthWaypoint,
    'waypoint_name': options.waypointName,
    'junction_name': (/*step.junction_name ??*/ '').split(';')[0]
  };

  return tokenize(language, instruction, replaceTokens, options);
}

String grammarize(String language, String name, String grammar) {
  if (language == null) throw ('No language code provided');
  // Process way/rotary/any name with applying grammar rules if any
  if (grammar != null &&
      grammars != null &&
      grammars[language] != null &&
      grammars[language][version] != null) {
    List<List<String>> rules = grammars[language][version][grammar];
    if (rules != null) {
      // Pass original name to rules' regular expressions enclosed with spaces for simplier parsing
      String n = ' $name ';
      String flags = grammars[language]["meta"]["regExpFlags"] ?? '';
      rules.forEach((rule) {
        RegExp re = RegExp("${rule[0]}/$flags");
        n = n.replaceAll(re, rule[1]);
      });

      return n.trim();
    }
  }

  return name;
}

String tokenize(
  String language,
  String instruction,
  Map<String, String> tokens,
  Options options,
) {
  if (language == null) throw ('No language code provided');
  // Keep this function context to use in inline function below (no arrow functions in ES4)
  bool startedWithToken = false;
  String output = instruction.replaceAllMapped(
      RegExp(
        r"\{(\w+)(?::(\w+))?\}",
        caseSensitive: false,
      ), (Match match) {
    String token = match[0];
    String tag = match[1];
    String grammar = match[2];
    int offset = match.start;
    String value = tokens[tag];

    // Return unknown token unchanged
    if (value == null) {
      return token;
    }

    value = grammarize(language, value, grammar);

    // If this token appears at the beginning of the instruction, capitalize it.
    if (offset == 0 &&
        instructions[language]["meta"]["capitalizeFirstLetter"] != null) {
      startedWithToken = true;
      value = capitalizeFirstLetter(language, value);
    }

    if (options != null && options.formatToken != null) {
      value = options.formatToken(tag, value);
    }

    return value;
  }).replaceAll(r"/ {2}/g", ' '); // remove excess spaces

  if (!startedWithToken &&
      instructions[language]["meta"]["capitalizeFirstLetter"] != null) {
    return capitalizeFirstLetter(language, output);
  }

  return output;
}

class Options {
  int legCount;
  int legIndex;
  String Function(String token, String value) formatToken;
  String waypointName;
  List<String> classes;
}
