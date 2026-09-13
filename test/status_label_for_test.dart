import 'package:flutter_test/flutter_test.dart';

import 'package:mjcc/data/models/health_facility.dart';
import 'package:mjcc/data/models/school.dart';
import 'package:mjcc/presentation/screens/data/public_data_entity.dart';

void main() {
  test('school maps its nullable isActive to a status label', () {
    expect(
      statusLabelFor(PublicDataEntity.school, const School(id: 1, isActive: true)),
      'Aktif',
    );
    expect(
      statusLabelFor(
        PublicDataEntity.school,
        const School(id: 2, isActive: false),
      ),
      'Tidak aktif',
    );
    expect(
      statusLabelFor(PublicDataEntity.school, const School(id: 3)),
      isNull,
    );
  });

  test('entities exposing a status field keep their value', () {
    expect(
      statusLabelFor(
        PublicDataEntity.healthFacility,
        const HealthFacility(id: 1, name: 'Puskesmas', status: 'aktif'),
      ),
      'aktif',
    );
    expect(
      statusLabelFor(
        PublicDataEntity.healthFacility,
        const HealthFacility(id: 2, name: 'RS'),
      ),
      isNull,
    );
  });

  test('school status lookup never throws a NoSuchMethodError', () {
    // Regression: `(item as dynamic).status` used to throw for School (it has
    // no `status` getter), which blanked the Pendidikan list on real data.
    expect(
      () => statusLabelFor(PublicDataEntity.school, const School(id: 1)),
      returnsNormally,
    );
  });
}