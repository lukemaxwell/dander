# SPEC: Quiz Reframe — "How Well Do You Know Your Neighbourhood?"

## Goal
Transform the quiz from street-name-only flashcards into a multi-type neighbourhood knowledge test that feels like a pub quiz about your world, using data from streets, discoveries, and walk history.

## Non-goals
- Multiplayer/competitive quiz modes
- Questions about places the user hasn't visited
- Showing raw GPS coordinates to users
- Replacing spaced repetition — it still drives scheduling
- Generating questions from external data (Wikipedia, etc.) — all questions derive from the user's own exploration data

## Users / scenario
A user who has walked several routes and discovered POIs opens the Quiz tab. Instead of only "What street is this?", they see a mix of question types: compass direction challenges, "nearest POI" proximity questions, category identification, and route recall. The session feels varied and fun — like testing genuine local knowledge, not memorising a list. Their knowledge score (%) reflects mastery across all types.

## Requirements (must)
- [ ] `QuestionType` enum with at least 5 types: `streetName`, `direction`, `proximity`, `category`, `route`
- [ ] New `QuizQuestion` model that supports all question types (type field, flexible prompt/answer structure)
- [ ] `QuestionGenerator` service that produces questions from streets, discoveries, and walk history
- [ ] Direction questions: "Which direction is [POI] from [street/POI]?" — 4 compass options (N/NE/E/SE/S/SW/W/NW)
- [ ] Proximity questions: "What's the nearest [category] to [POI name]?" — 4 POI name options
- [ ] Category questions: "What type of place is [POI name]?" — 4 category options
- [ ] Route questions: "What street connects [POI A] and [POI B]?" — 4 street name options (POIs must be from same walk)
- [ ] Questions only reference data the user has actually walked/discovered
- [ ] Each question type has a distinct visual header (icon + type label) so the user knows what's being asked
- [ ] Spaced repetition applies per question (not per street) — wrong answers resurface sooner
- [ ] `MemoryRecord` generalised from street-only to support any question ID
- [ ] Knowledge score: percentage of mastered questions across all types, shown on quiz home screen
- [ ] Mixed sessions: questions drawn from all available types, weighted by spaced repetition priority
- [ ] Graceful degradation: if insufficient data for a question type (e.g., < 4 POIs), skip that type silently

## Nice-to-haves
- [ ] "Streak bonus" question — harder question after 5 correct in a row
- [ ] Question type filter on quiz home screen (practice just directions, just categories, etc.)
- [ ] Animated compass rose widget for direction questions instead of text buttons
- [ ] "Discovery date" question type: "When did you discover [POI]?" — month/season options

## Acceptance criteria (definition of done)
- [ ] Quiz sessions contain a mix of at least 3 question types (when data supports it)
- [ ] Direction questions show compass options and calculate correct answer from lat/lng bearing
- [ ] Proximity questions use Haversine distance to determine the genuinely nearest POI
- [ ] Category questions only use POIs with known non-"unknown" categories
- [ ] Route questions only reference POIs discovered during the same walk session
- [ ] Wrong answers decrease interval (SM-2), correct answers increase it — for all types
- [ ] Knowledge score displayed as "X% neighbourhood knowledge" on quiz home screen
- [ ] All existing quiz tests still pass (backwards compatible with street-name questions)
- [ ] At least 80% test coverage on new question generation and answer validation logic
- [ ] No raw coordinates visible anywhere in the UI

## Risks / constraints
- **Minimum data thresholds**: Direction/proximity/category questions need ≥4 POIs discovered. Route questions need walks with ≥2 POIs. If user has only walked once with no POIs, quiz falls back to street-name-only gracefully.
- **Compass bearing accuracy**: Bearing calculation from lat/lng is straightforward but the "correct" compass direction must account for the 8-point compass (45° sectors). Edge cases at sector boundaries need rounding.
- **Migration**: Existing `StreetMemoryRecord` is keyed by street ID. New system needs a generalised `MemoryRecord` keyed by question ID (e.g., `street:way/123`, `direction:poi1-poi2`, `category:node/456`). Must migrate existing records without data loss.
- **Question uniqueness**: Same POI pair could generate both a direction and proximity question. Question IDs must encode the type to prevent deduplication bugs.
- **Session size**: Current max is 20 questions. With more types, maintain this cap but ensure type diversity (no more than 8 of any single type per session).

## Issue breakdown

### Issue 1: Generalise QuizQuestion model and QuestionType enum
- **Description**: Replace the current street-only `QuizQuestion` with a generalised model that supports multiple question types. Add `QuestionType` enum. Generalise `MemoryRecord` from street-specific to question-ID-based. Migrate existing `StreetMemoryRecord` data.
- **Acceptance**: QuizQuestion has `type`, `prompt`, `choices`, `correctIndex`, `questionId` fields. MemoryRecord keyed by question ID. Existing street memory records migrated to new format.
- **Test plan**: Unit tests for model creation per type, JSON round-trip, migration of legacy records.

### Issue 2: Direction question generator
- **Description**: Generate "Which direction is [POI] from [POI/street]?" questions. Calculate compass bearing between two lat/lng points, map to 8-point compass. Produce 4 compass choices with correct answer.
- **Acceptance**: Given ≥2 discovered POIs, generates direction questions with correct compass bearing. Skipped if <2 POIs.
- **Test plan**: Unit tests for bearing calculation, compass sector mapping, question generation with known coordinates.

### Issue 3: Proximity question generator
- **Description**: Generate "What's the nearest [category] to [POI]?" questions. Use Haversine distance to find the genuinely nearest POI of a given category, generate 3 distractor POIs.
- **Acceptance**: Correct answer is the actual nearest POI. Distractors are real POIs but further away. Skipped if <4 POIs.
- **Test plan**: Unit tests with known POI positions verifying nearest is correct. Edge case: all POIs equidistant.

### Issue 4: Category question generator
- **Description**: Generate "What type of place is [POI name]?" questions. Use the discovery's `category` field. Produce 4 category choices with the correct one included.
- **Acceptance**: Only uses POIs with non-"unknown" categories. Distractors are categories that exist in the user's discovery set. Skipped if <4 distinct categories.
- **Test plan**: Unit tests for category extraction, distractor selection, graceful skip.

### Issue 5: Route question generator
- **Description**: Generate "What street connects [POI A] and [POI B]?" questions. Cross-reference walk track points with street geometry and POI positions to find POIs discovered on the same walk, then identify the connecting street.
- **Acceptance**: Both POIs were discovered during the same walk session. The correct street's geometry passes near both POIs. Skipped if no walks have ≥2 POI discoveries.
- **Test plan**: Unit tests with synthetic walk data and known POI/street positions.

### Issue 6: Mixed session builder and knowledge score
- **Description**: Build quiz sessions that mix all available question types. Weight selection by spaced repetition priority. Cap at 20 questions with type diversity (max 8 per type). Calculate and display knowledge score (% mastered across all question types) on quiz home screen.
- **Acceptance**: Sessions contain a mix of types when data supports it. Knowledge score shown as percentage. Home screen updated with new stats.
- **Test plan**: Unit tests for session building with various data availability. Widget test for knowledge score display.

### Issue 7: Question-type-aware UI
- **Description**: Update `QuizQuestionScreen` to render different visual headers per question type (icon + label). Direction questions show compass options. Street-name questions keep the map snippet. Other types show the POI name/context prominently. Update `QuizHomeScreen` to show knowledge score and question type breakdown.
- **Acceptance**: Each question type visually distinct. Map snippet only for street-name type. Compass layout for direction type. Text-prominent layout for category/proximity/route.
- **Test plan**: Widget tests for each question type rendering. Verify correct icon/label per type.

## PR discipline
- Branch → PR only
- PR body includes: `Closes #…`
- Commands to run (paste output in PR):
  - `flutter analyze`
  - `flutter test`
