import 'package:flutter/material.dart';
import 'package:rosivia/Feature/auth/auth_routes.dart';
import 'package:rosivia/Feature/intro/onboarding/data/onboarding_data.dart';
import 'package:rosivia/core/services/intro_prefs.dart';
import 'package:rosivia/core/styles/colors.dart';
import 'package:rosivia/core/widgets/main_button.dart';
import 'package:rosivia/l10n/app_localizations.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _controller = PageController();

  int currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> finishOnboarding() async {
    // Remember the intro was completed so every later launch skips
    // straight to AuthGate (see SplashScreen._route).
    await IntroPrefs.setIntroSeen();
    if (!mounted) return;
    // Named replacement -> the URL becomes `#/` (app root), never stays
    // on `#/splash`.
    Navigator.of(context).pushReplacementNamed(AuthRoutes.gate);
  }

  void nextPage() {
    if (currentIndex == onboardingList.length - 1) {
      finishOnboarding();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    String title() {
      switch (currentIndex) {
        case 0:
          return lang.onboardingTitle1;
        case 1:
          return lang.onboardingTitle2;
        default:
          return lang.onboardingTitle3;
      }
    }

    String description() {
      switch (currentIndex) {
        case 0:
          return lang.onboardingDescription1;
        case 1:
          return lang.onboardingDescription2;
        default:
          return lang.onboardingDescription3;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      // Constrain to a centred phone-width panel on tablet/desktop so
      // the onboarding art doesn't stretch across the whole monitor.
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return Stack(
                children: [
                  PageView.builder(
                    controller: _controller,
                    itemCount: onboardingList.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _OnboardingPage(
                        item: onboardingList[index],
                        screenSize: size,
                      );
                    },
                  ),

                  /// Skip Button
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 15,
                    right: 20,
                    child: GestureDetector(
                      onTap: finishOnboarding,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          lang.skip,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  /// Bottom Card
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        30,
                        24,
                        MediaQuery.of(context).padding.bottom + 25,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(35),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /// Dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(onboardingList.length, (
                              index,
                            ) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: currentIndex == index ? 28 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: currentIndex == index
                                      ? AppColors.primary
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 25),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              title(),
                              key: ValueKey(currentIndex),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff1A1A2E),
                                height: 1.3,
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              description(),
                              key: ValueKey("desc$currentIndex"),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 15,
                                height: 1.6,
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          MainButton(
                            text: currentIndex == onboardingList.length - 1
                                ? lang.getStarted
                                : lang.next,
                            onpress: nextPage,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final dynamic item;
  final Size screenSize;

  const _OnboardingPage({required this.item, required this.screenSize});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: screenSize.height * 0.55,
          child: Image.asset(item.image, fit: BoxFit.cover),
        ),

        Positioned(
          top: screenSize.height * 0.38,
          left: 0,
          right: 0,
          height: screenSize.height * 0.17,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.white, Colors.white.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
