/// The types of quiz questions available in the neighbourhood knowledge test.
enum QuestionType {
  /// "What street is this?" — identify a street from a map snippet.
  streetName,

  /// "Which direction is [POI] from [POI]?" — compass bearing question.
  direction,

  /// "What's the nearest [category] to [POI]?" — Haversine distance question.
  proximity,

  /// "What type of place is [POI]?" — identify a POI's category.
  category,

  /// "What street connects [POI A] and [POI B]?" — route recall question.
  route,
}
