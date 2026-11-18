import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/night_weather.dart';

/// Set once the tutorial has been finished or skipped on first launch.
const tutorialSeenKey = 'tutorial_seen';

/// Pages in the order they appear, so a help button can open its own page.
enum TutorialTopic { welcome, voiding, enuresis, bowel, rewards, tips }

class _TutorialPage {
  final Widget art;
  final Color color;
  final String title;
  final String intro;
  final List<String> steps;

  const _TutorialPage({
    required this.art,
    required this.color,
    required this.title,
    required this.intro,
    required this.steps,
  });
}

const _pages = {
  TutorialTopic.welcome: _TutorialPage(
    art: Text('🌱', style: TextStyle(fontSize: 64)),
    color: AppColors.primary,
    title: 'به بهروان خوش آمدید',
    intro:
        'بهروان دفترچه روزانه ادرار و مدفوع کودک است. با ثبت منظم، پزشک می‌بیند '
        'مثانه و روده کودک چطور کار می‌کنند و برنامه درمان را دقیق‌تر تنظیم می‌کند.',
    steps: [
      'چهار بخش اصلی: ادرار در طول روز، شب‌ادراری، مدفوع، و گزارش.',
      'هر ثبت، ستاره می‌دهد و باغ کودک را بزرگ‌تر می‌کند.',
      'همه اطلاعات فقط روی همین گوشی ذخیره می‌شود.',
      'هر وقت خواستید، دکمه ؟ بالای هر صفحه همین راهنما را باز می‌کند.',
    ],
  ),
  TutorialTopic.voiding: _TutorialPage(
    art: Icon(Icons.timer_rounded, size: 64, color: AppColors.primary),
    color: AppColors.primary,
    title: 'تمرین مثانه (ادرار)',
    intro:
        'در طول روز، کودک طبق یک برنامه زمانی به دستشویی می‌رود تا مثانه کم‌کم '
        'قوی‌تر شود و گنجایش بیشتری پیدا کند.',
    steps: [
      'ساعت شمارش، زمان نوبت بعدی را نشان می‌دهد و گوشی یادآوری می‌کند.',
      'با هر یادآوری به دستشویی بروید، حتی اگر کودک احساس نیاز نکند.',
      'بعد از هر بار دستشویی، همان لحظه دکمه ثبت را بزنید.',
      'اگر لباس خیس شد، آن را هم صادقانه ثبت کنید؛ بخشی از یادگیری است.',
      'هر ۳ روز برنامه بررسی می‌شود و در صورت پیشرفت، فاصله‌ها بیشتر می‌شود.',
    ],
  ),
  TutorialTopic.enuresis: _TutorialPage(
    art: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NightWeatherIcon(isDry: true, size: 58),
        SizedBox(width: 12),
        NightWeatherIcon(isDry: false, size: 58),
      ],
    ),
    color: AppColors.rainy,
    title: 'شب‌ادراری: آفتابی یا بارانی؟',
    intro:
        'هر روز صبح، وضعیت شب قبل را ثبت کنید. شب خشک یک روز آفتابی است و '
        'شب خیس یک روز بارانی؛ بعد از هر باران، آفتاب درمی‌آید!',
    steps: [
      'صبح‌ها اول کار، «شب خشک» ☀️ یا «شب خیس» 🌧️ را بزنید.',
      'اگر محدودیت مایعات عصر رعایت شد یا کودک برای دستشویی بیدار شد، در جزئیات علامت بزنید.',
      'شب‌های فراموش‌شده را با زدن روی همان روز در تقویم ثبت کنید.',
      'ردیف «هفته من» نشان می‌دهد چند شب آفتابی پشت سر هم داشته‌اید.',
    ],
  ),
  TutorialTopic.bowel: _TutorialPage(
    art: Icon(
      Icons.health_and_safety_rounded,
      size: 64,
      color: AppColors.success,
    ),
    color: AppColors.success,
    title: 'مدفوع و مقیاس بریستول',
    intro:
        'یبوست یکی از دلایل رایج مشکلات ادراری کودکان است، پس ثبت مدفوع هم '
        'به همان اندازه مهم است.',
    steps: [
      'بعد از هر بار مدفوع، تصویری را انتخاب کنید که بیشترین شباهت را دارد.',
      'نوع ۳ تا ۵ ایده‌آل است؛ ۱ و ۲ یعنی یبوست و ۶ و ۷ یعنی مدفوع شل.',
      'زور زدن و کثیف شدن لباس را هم علامت بزنید.',
      'اگر خون در مدفوع دیدید، ثبت کنید و حتماً به پزشک خبر دهید.',
    ],
  ),
  TutorialTopic.rewards: _TutorialPage(
    art: Text('🏆', style: TextStyle(fontSize: 64)),
    color: AppColors.sunnyDark,
    title: 'ستاره، مرحله و نشان',
    intro:
        'هر ثبت ستاره می‌دهد. با جمع شدن ستاره‌ها، باغ کودک از جوانه تا قهرمان '
        'باغ رشد می‌کند و نشان‌های تازه باز می‌شوند.',
    steps: [
      'شب آفتابی ۳ ستاره و دستشویی رفتن با یادآوری ۲ ستاره دارد.',
      'شب بارانی و خیس شدن هم ۱ ستاره دارند؛ راستگویی جایزه دارد!',
      'نشان‌ها برای شب‌های خشک پشت سر هم، ثبت منظم و عادت‌های خوب است.',
      'در بخش جایزه‌ها، «هدف بعدی» را با هم ببینید و برایش برنامه بریزید.',
    ],
  ),
  TutorialTopic.tips: _TutorialPage(
    art: Text('💡', style: TextStyle(fontSize: 64)),
    color: AppColors.primaryDark,
    title: 'برای نتیجه درست (ویژه والدین)',
    intro:
        'گزارش فقط وقتی به پزشک کمک می‌کند که کامل و واقعی باشد. این نکته‌ها را '
        'رعایت کنید:',
    steps: [
      'همه اتفاق‌ها را بلافاصله ثبت کنید، نه آخر شب از روی حافظه.',
      'خیس شدن را هرگز پنهان نکنید و کودک را برای آن سرزنش یا تنبیه نکنید.',
      'اعلان‌های برنامه را روشن نگه دارید تا یادآوری‌ها از دست نرود.',
      'روز به اندازه کافی آب بنوشد و از عصر مایعات و نوشیدنی کافئین‌دار کم شود.',
      'دست‌کم دو هفته پیش از ویزیت ثبت کنید و از بخش گزارش، PDF یا اکسل را برای پزشک بفرستید.',
    ],
  ),
};

/// Opens the tutorial on the page for [topic].
class TutorialButton extends StatelessWidget {
  final TutorialTopic topic;

  const TutorialButton({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'راهنما',
      icon: const Icon(Icons.help_outline_rounded, color: AppColors.muted),
      onPressed: () => TutorialScreen.open(context, topic: topic),
    );
  }
}

class TutorialScreen extends StatefulWidget {
  final TutorialTopic initialTopic;

  const TutorialScreen({super.key, this.initialTopic = TutorialTopic.welcome});

  static Future<void> open(
    BuildContext context, {
    TutorialTopic topic = TutorialTopic.welcome,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => TutorialScreen(initialTopic: topic),
      ),
    );
  }

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late final PageController _controller;
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = widget.initialTopic.index;
    _controller = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) => _controller.animateToPage(
    page,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    const topics = TutorialTopic.values;
    final isLast = _page == topics.length - 1;
    final color = _pages[topics[_page]]!.color;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          'راهنما  ${_page + 1} از ${topics.length}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isLast ? 'بستن' : 'رد شدن'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  for (final topic in topics) _PageBody(page: _pages[topic]!),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < topics.length; i++)
                  GestureDetector(
                    onTap: () => _goTo(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 8,
                      ),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? color : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  if (_page > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _goTo(_page - 1),
                        child: const Text('قبلی'),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: color),
                      onPressed: isLast
                          ? () => Navigator.of(context).pop()
                          : () => _goTo(_page + 1),
                      child: Text(isLast ? 'شروع کنیم! 🚀' : 'بعدی'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageBody extends StatelessWidget {
  final _TutorialPage page;

  const _PageBody({required this.page});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      children: [
        Center(
          child: Container(
            width: 128,
            height: 128,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: page.art,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          page.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          page.intro,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.7,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 18),
        for (final (i, step) in page.steps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: page.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: page.color,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    step,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.6,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
