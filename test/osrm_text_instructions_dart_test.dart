import 'package:flutter_test/flutter_test.dart';
import 'package:osrm_dart_sdk/api.dart';
import 'package:osrm_text_instructions_dart/osrm_text_instructions_dart.dart' as osrmTextInstructions;
import 'package:osrm_text_instructions_dart/languages.dart' as osrmTextInstructionsLanguages;

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await osrmTextInstructionsLanguages.loadLanguage("de");

  test('Süden Friedrichstraße', () {
    expect(
      osrmTextInstructions.compile(
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
          drivingSide: RouteStepDrivingSideEnum.right,
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
      ),
      equals("Fahren Sie Richtung Süden auf Friedrichstraße"),
    );
  });

  test('Abbiegen Habichtweg', () {
    expect(
      osrmTextInstructions.compile(
        language: "de",
        step: RouteStep(
          intersections: [
            Intersection(
              out_: 1,
              in_: 0,
              entry: [false, true, true],
              location: [8.826778, 52.982959],
              bearings: [0, 90, 195],
            ),
          ],
          drivingSide: RouteStepDrivingSideEnum.right,
          geometry: "ofkbIk~zt@CKDYn@wA",
          duration: 45.0,
          distance: 54.1,
          name: "Habichtweg",
          weight: 45.0,
          mode: "cycling",
          maneuver: StepManeuver(
            bearingAfter: 177,
            bearingBefore: 87,
            type: "turn",
            modifier: "left",
            location: [8.826778, 52.982959],
          ),
        ),
      ),
      equals("Links abbiegen auf Habichtweg"),
    );
  });
}
