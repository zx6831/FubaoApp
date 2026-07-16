# Fubao Flutter MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a runnable Flutter iOS-first app that implements the approved child and elder experiences with a mock repository and API-ready boundaries.

**Architecture:** Feature-first Flutter app with a shared design system, role-aware shell, immutable domain models, and repository interfaces. Initial data comes from an in-memory repository so every approved flow runs before the cloud API is connected.

**Tech Stack:** Flutter stable, Dart 3, Material 3, Riverpod, go_router, flutter_test

## Global Constraints

- One app contains child and elder roles; users cannot access another role's privileged actions.
- Child navigation: 首页、计划、话题、我的. Elder navigation: 首页、计划、话题、我的.
- Colors: mint `#86D2B2`, orange `#F7B267`, brick `#C97064`, ink `#252525`, canvas `#FBF9F6`.
- Elder controls have a minimum logical touch target of 60x60 and use large Chinese type.
- The app provides health-management reminders only and never makes diagnosis or treatment claims.
- The nine PNG files under `demo_images/` are visual references, not full-screen runtime assets.

---

### Task 1: Flutter project foundation and design system

**Files:**
- Create: `apps/fubao_app/pubspec.yaml`
- Create: `apps/fubao_app/lib/main.dart`
- Create: `apps/fubao_app/lib/app/fubao_app.dart`
- Create: `apps/fubao_app/lib/design/fubao_colors.dart`
- Create: `apps/fubao_app/lib/design/fubao_theme.dart`
- Test: `apps/fubao_app/test/design/fubao_theme_test.dart`

**Interfaces:**
- Produces: `FubaoColors`, `buildFubaoTheme()`, `FubaoApp`.

- [ ] **Step 1: Write the failing theme test**

```dart
test('theme uses the approved mint color', () {
  expect(buildFubaoTheme().colorScheme.primary, const Color(0xFF86D2B2));
});
```

- [ ] **Step 2: Run the focused test**

Run: `flutter test test/design/fubao_theme_test.dart`
Expected: FAIL because `buildFubaoTheme` is not defined.

- [ ] **Step 3: Implement the theme and app entry point**

```dart
abstract final class FubaoColors {
  static const mint = Color(0xFF86D2B2);
  static const orange = Color(0xFFF7B267);
  static const brick = Color(0xFFC97064);
  static const ink = Color(0xFF252525);
  static const canvas = Color(0xFFFBF9F6);
}
```

- [ ] **Step 4: Run the test suite**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 5: Commit the foundation**

```bash
git add apps/fubao_app
git commit -m "feat: scaffold fubao flutter app"
```

### Task 2: Domain models, role session, and demo repository

**Files:**
- Create: `apps/fubao_app/lib/domain/app_role.dart`
- Create: `apps/fubao_app/lib/domain/health_task.dart`
- Create: `apps/fubao_app/lib/domain/plan.dart`
- Create: `apps/fubao_app/lib/domain/topic.dart`
- Create: `apps/fubao_app/lib/data/fubao_repository.dart`
- Create: `apps/fubao_app/lib/data/demo_fubao_repository.dart`
- Create: `apps/fubao_app/lib/state/app_providers.dart`
- Test: `apps/fubao_app/test/data/demo_fubao_repository_test.dart`

**Interfaces:**
- Produces: `enum AppRole { child, elder }` and `FubaoRepository` methods `todayTasks()`, `plans()`, `topics()`, `completeTask(String id)`.

- [ ] **Step 1: Write repository behavior tests**

```dart
test('completing medicine task updates progress', () async {
  final repository = DemoFubaoRepository();
  await repository.completeTask('medicine');
  final tasks = await repository.todayTasks();
  expect(tasks.singleWhere((task) => task.id == 'medicine').isCompleted, isTrue);
});
```

- [ ] **Step 2: Run the test and confirm failure**

Run: `flutter test test/data/demo_fubao_repository_test.dart`
Expected: FAIL because the repository is absent.

- [ ] **Step 3: Implement immutable models and demo data**

```dart
abstract interface class FubaoRepository {
  Future<List<HealthTask>> todayTasks();
  Future<List<HealthPlan>> plans();
  Future<List<CareTopic>> topics();
  Future<void> completeTask(String id);
}
```

- [ ] **Step 4: Run repository tests**

Run: `flutter test test/data/demo_fubao_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit domain and data boundaries**

```bash
git add apps/fubao_app/lib/domain apps/fubao_app/lib/data apps/fubao_app/lib/state apps/fubao_app/test/data
git commit -m "feat: add role-aware demo data"
```

### Task 3: Role selection and shared navigation shell

**Files:**
- Create: `apps/fubao_app/lib/navigation/app_router.dart`
- Create: `apps/fubao_app/lib/features/auth/role_selection_page.dart`
- Create: `apps/fubao_app/lib/widgets/fubao_bottom_navigation.dart`
- Test: `apps/fubao_app/test/features/auth/role_selection_page_test.dart`

**Interfaces:**
- Consumes: `AppRole` and `FubaoApp`.
- Produces: routes `/role`, `/child/home`, `/elder/home`; `FubaoBottomNavigation`.

- [ ] **Step 1: Write the role routing widget test**

```dart
testWidgets('selecting elder opens elder home', (tester) async {
  await tester.pumpWidget(const ProviderScope(child: FubaoApp()));
  await tester.tap(find.text('我是长辈'));
  await tester.pumpAndSettle();
  expect(find.text('早上好，王阿姨'), findsOneWidget);
});
```

- [ ] **Step 2: Run the focused test**

Run: `flutter test test/features/auth/role_selection_page_test.dart`
Expected: FAIL before routes and the selection page exist.

- [ ] **Step 3: Implement role selection and navigation**

Use two 96pt rounded role cards labelled `我是子女` and `我是长辈`; persist the selected role in Riverpod state for the current demo session.

- [ ] **Step 4: Run role navigation tests**

Run: `flutter test test/features/auth/role_selection_page_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit navigation**

```bash
git add apps/fubao_app/lib/navigation apps/fubao_app/lib/features/auth apps/fubao_app/lib/widgets apps/fubao_app/test/features/auth
git commit -m "feat: add child and elder app shells"
```

### Task 4: Child-role approved pages

**Files:**
- Create: `apps/fubao_app/lib/features/child/child_home_page.dart`
- Create: `apps/fubao_app/lib/features/child/child_plans_page.dart`
- Create: `apps/fubao_app/lib/features/child/create_plan_page.dart`
- Create: `apps/fubao_app/lib/features/child/child_topics_page.dart`
- Create: `apps/fubao_app/lib/features/child/child_profile_page.dart`
- Test: `apps/fubao_app/test/features/child/child_pages_test.dart`

**Interfaces:**
- Consumes: repository providers and shared navigation.
- Produces: four child tabs and the create-plan flow.

- [ ] **Step 1: Write child-page smoke tests**

```dart
testWidgets('child plans show approved progress and add action', (tester) async {
  await tester.pumpWidget(testAppAt('/child/plans'));
  await tester.pumpAndSettle();
  expect(find.text('本周完成情况'), findsOneWidget);
  expect(find.text('添加计划'), findsOneWidget);
});
```

- [ ] **Step 2: Run child-page tests**

Run: `flutter test test/features/child/child_pages_test.dart`
Expected: FAIL before the pages exist.

- [ ] **Step 3: Implement child screens from the five approved references**

Build the spark hero, task progress, health cards, weekly/monthly plan progress, active plans, copyable topics, profile menus, and three-step plan creation flow using live widgets and demo models.

- [ ] **Step 4: Run child tests**

Run: `flutter test test/features/child/child_pages_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit child experience**

```bash
git add apps/fubao_app/lib/features/child apps/fubao_app/test/features/child
git commit -m "feat: implement child care experience"
```

### Task 5: Elder-role approved pages and accessibility

**Files:**
- Create: `apps/fubao_app/lib/features/elder/elder_home_page.dart`
- Create: `apps/fubao_app/lib/features/elder/elder_plans_page.dart`
- Create: `apps/fubao_app/lib/features/elder/elder_topics_page.dart`
- Create: `apps/fubao_app/lib/features/elder/elder_profile_page.dart`
- Create: `apps/fubao_app/lib/widgets/read_aloud_button.dart`
- Test: `apps/fubao_app/test/features/elder/elder_pages_test.dart`

**Interfaces:**
- Consumes: repository providers and shared navigation.
- Produces: four elder tabs, task completion actions, and `ReadAloudButton`.

- [ ] **Step 1: Write elder accessibility and task tests**

```dart
testWidgets('elder medicine choices have large tap targets', (tester) async {
  await tester.pumpWidget(testAppAt('/elder/home'));
  await tester.pumpAndSettle();
  expect(tester.getSize(find.text('我已经吃了').first).height, greaterThanOrEqualTo(60));
});
```

- [ ] **Step 2: Run elder tests**

Run: `flutter test test/features/elder/elder_pages_test.dart`
Expected: FAIL before the elder pages exist.

- [ ] **Step 3: Implement elder pages from the four approved references**

Use 28–36pt headings, 60pt or larger controls, a persistent read-aloud action, one-tap task states, short topic prompts, and first-level accessibility settings.

- [ ] **Step 4: Run elder tests**

Run: `flutter test test/features/elder/elder_pages_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit elder experience**

```bash
git add apps/fubao_app/lib/features/elder apps/fubao_app/lib/widgets/read_aloud_button.dart apps/fubao_app/test/features/elder
git commit -m "feat: implement elder accessible experience"
```

### Task 6: End-to-end demo verification and handoff

**Files:**
- Create: `apps/fubao_app/integration_test/app_flow_test.dart`
- Create: `apps/fubao_app/README.md`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: all routes and demo repository behavior.
- Produces: reproducible launch and test commands.

- [ ] **Step 1: Write the end-to-end demo flow**

```dart
testWidgets('elder completes a task and child sees updated progress', (tester) async {
  app.main();
  await tester.pumpAndSettle();
  await tester.tap(find.text('我是长辈'));
  await tester.tap(find.text('我已经吃了'));
  expect(find.text('已完成'), findsWidgets);
});
```

- [ ] **Step 2: Run all static and automated checks**

Run: `flutter analyze; flutter test`
Expected: zero analyzer issues and all tests PASS.

- [ ] **Step 3: Run the app locally**

Run: `flutter run -d windows`
Expected: role selection opens and all eight tab pages are navigable.

- [ ] **Step 4: Document iOS handoff**

Document macOS/Xcode requirements, `flutter build ios`, signing, and TestFlight steps without claiming a Windows machine can produce an iOS archive.

- [ ] **Step 5: Commit verified demo**

```bash
git add apps/fubao_app .gitignore
git commit -m "test: verify fubao demo flows"
```
