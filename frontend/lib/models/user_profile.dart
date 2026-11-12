class ElderlyProfile {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String bloodGroup;
  final String address;
  final String phone;
  final String linkingCode;
  final List<String> chronicConditions;
  final List<String> allergies;
  final String primaryDoctor;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String emergencyContactRelation;
  final String avatarAsset;

  const ElderlyProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.bloodGroup,
    required this.address,
    required this.phone,
    required this.linkingCode,
    required this.chronicConditions,
    required this.allergies,
    required this.primaryDoctor,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.emergencyContactRelation,
    required this.avatarAsset,
  });
}

class CaregiverProfileData {
  final String id;
  final String name;
  final String relation;
  final String email;
  final String phone;
  final String avatarAsset;
  final List<String> linkedElderlyCodes;

  const CaregiverProfileData({
    required this.id,
    required this.name,
    required this.relation,
    required this.email,
    required this.phone,
    required this.avatarAsset,
    required this.linkedElderlyCodes,
  });
}
