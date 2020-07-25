import 'package:osrm_dart_sdk/api.dart';
import 'package:osrm_text_instructions_dart/osrm_text_instructions_dart.dart' as osrmTextInstructions;
import 'package:test/test.dart';

void main() {
  test('adds one to input values', () {
    print(osrmTextInstructions.compile(
      language: "de",
      step: RouteStep(
        intersections: [
          Intersection(
            out_: 0,
            entry: [true],
            location: [13.388798, 52.517033],
            bearings: [175],
          ),
        ],
        drivingSide: RouteStepDrivingSideEnum.right_,
        geometry: "mfp_I__vpAb@E",
        duration: 7.4,
        distance: 20.7,
        name: "Friedrichstraße",
        weight: 9.3,
        mode: "driving",
        maneuver: StepManeuver(
          bearingAfter: 175,
          bearingBefore: 0,
          type: "depart",
          location: [13.388798, 52.517033],
        ),
      ),
    ));
  });
}
