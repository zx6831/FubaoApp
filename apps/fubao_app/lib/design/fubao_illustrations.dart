enum FubaoIllustration {
  brandLogo('brand-logo.png'),
  spark('spark.png'),
  clipboard('clipboard.png'),
  mood('mood.png'),
  coffee('coffee.png'),
  sofa('sofa.png'),
  planClipboard('plan-clipboard.png'),
  walkingPerson('walking-person.png'),
  mascotBanner('mascot-banner.png'),
  bloodPressureDevice('blood-pressure-device.png'),
  medicineBox('medicine-box.png'),
  walkingShoe('walking-shoe.png'),
  pencil('pencil.png'),
  park('park.png'),
  mascotAvatar('mascot-avatar.png'),
  plants('plants.png'),
  pill('pill.png'),
  elderBloodPressureDevice('elder-bp-device.png'),
  elderPark('elder-park.png'),
  elderMood('elder-mood.png'),
  elderTopicHero('elder-topic-hero.png'),
  elderSun('elder-sun.png'),
  elderProfileMascot('elder-profile-mascot.png');

  const FubaoIllustration(this.fileName);

  final String fileName;
  String get assetPath => 'assets/images/$fileName';
}
