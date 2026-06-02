import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/sushi_design.dart';

// ── Seuls deux modes : alpha ou numérique (symbols supprimé) ─────────────────
enum _KeyboardLayoutMode { auto, alpha, numeric }

// ── Palette interne du clavier ───────────────────────────────────────────────
class _KB {
  // Fond général
  static const bg = Color(0xFFF0F4F8);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFD6E0EA);

  // Touche standard
  static const keyBg = Color(0xFFFFFFFF);
  static const keyBorder = Color(0xFFCDD6DF);
  static final keyShadow = const Color(0xFF8FA8C0).withOpacity(0.28);
  static const keyText = Color(0xFF1A2B3C);

  // Touche action (submit / Valider)
  static const accentBg = Color(0xFF0E8CA0);
  static const accentText = Colors.white;

  // Touche secondaire (Effacer, Espace, Maj…)
  static const secondaryBg = Color(0xFFDDE6EF);
  static const secondaryText = Color(0xFF2E4A62);

  // Touche activée (Shift on)
  static const selectedBg = Color(0xFFBBD9E8);
  static const selectedText = Color(0xFF0E5870);

  // Séparateur header
  static const divider = Color(0xFFDEE8F0);
}

class TouchKeyboardHost extends StatefulWidget {
  const TouchKeyboardHost({
    super.key,
    required this.child,
    this.floatingKeyboard = true,
  });

  final Widget child;
  final bool floatingKeyboard;

  @override
  State<TouchKeyboardHost> createState() => _TouchKeyboardHostState();
}

class _TouchKeyboardHostState extends State<TouchKeyboardHost> {
  late final _TouchKeyboardController _controller;

  bool get _isDesktopTouchKeyboard =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void initState() {
    super.initState();
    _controller = _TouchKeyboardController();
    if (_isDesktopTouchKeyboard) {
      TextInput.ensureInitialized();
      TextInput.setInputControl(_controller);
    }
  }

  @override
  void dispose() {
    if (_isDesktopTouchKeyboard) {
      TextInput.restorePlatformInputControl();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDesktopTouchKeyboard) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final keyboardHeight = !widget.floatingKeyboard && _controller.visible
            ? _controller.keyboardViewportHeightFor(context)
            : 0.0;

        final screenSize = MediaQuery.sizeOf(context);
        final kbHeight = _controller.keyboardHeightFor(context);

        if (_controller.visible &&
            _controller.keyboardPosition == Offset.zero) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final maxWidth = _controller.keyboardMaxWidthFor(context);
            final newY = screenSize.height - kbHeight - 12;
            final newX = (screenSize.width - maxWidth) / 2;
            _controller.setKeyboardPosition(Offset(newX, newY));
          });
        }

        return Stack(
          children: [
            AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(bottom: keyboardHeight),
              child: widget.child,
            ),
            _TouchKeyboardPanel(controller: _controller),
          ],
        );
      },
    );
  }
}

// ── Controller ───────────────────────────────────────────────────────────────

class _TouchKeyboardController extends ChangeNotifier with TextInputControl {
  TextInputClient? _client;
  TextInputConfiguration _configuration = const TextInputConfiguration();
  TextEditingValue _value = TextEditingValue.empty;
  bool _visible = false;
  bool _shiftEnabled = false;
  _KeyboardLayoutMode _layoutMode = _KeyboardLayoutMode.auto;
  Offset _keyboardPosition = Offset.zero;

  bool get visible => _visible && _client != null;
  Offset get keyboardPosition => _keyboardPosition;

  void setKeyboardPosition(Offset position) {
    _keyboardPosition = position;
    notifyListeners();
  }

  TextInputType get inputType => _configuration.inputType;

  _KeyboardLayoutMode get effectiveLayoutMode {
    if (_layoutMode != _KeyboardLayoutMode.auto) return _layoutMode;
    return isNumericLayout
        ? _KeyboardLayoutMode.numeric
        : _KeyboardLayoutMode.alpha;
  }

  bool get isAlphaLayout => effectiveLayoutMode == _KeyboardLayoutMode.alpha;
  bool get isNumberPadLayout =>
      effectiveLayoutMode == _KeyboardLayoutMode.numeric;

  bool get isNumericLayout {
    final index = inputType.index;
    return index == TextInputType.number.index ||
        index == TextInputType.phone.index ||
        index == TextInputType.datetime.index;
  }

  bool get isSignedNumber =>
      inputType.index == TextInputType.number.index &&
      (inputType.signed ?? false);

  bool get isDecimalNumber =>
      inputType.index == TextInputType.number.index &&
      (inputType.decimal ?? false);

  bool get isPhoneLayout => inputType.index == TextInputType.phone.index;
  bool get isEmailLayout =>
      inputType.index == TextInputType.emailAddress.index;
  bool get isUrlLayout => inputType.index == TextInputType.url.index;

  bool get isMultiline =>
      inputType.index == TextInputType.multiline.index ||
      _configuration.inputAction == TextInputAction.newline;

  bool get shiftEnabled => _shiftEnabled;

  String get actionLabel {
    switch (_configuration.inputAction) {
      case TextInputAction.next:
        return 'Suivant';
      case TextInputAction.search:
        return 'Chercher';
      case TextInputAction.send:
        return 'Envoyer';
      case TextInputAction.go:
        return 'Ouvrir';
      default:
        return 'ok';
    }
  }

  double keyboardHeightFor(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (isNumberPadLayout) {
      if (w >= 1400) return 360;
      if (w >= 1000) return 340;
      return 320;
    }
    if (w >= 1400) return 286;
    if (w >= 1100) return 270;
    return 252;
  }

  double keyboardMaxWidthFor(BuildContext context) {
    final available = MediaQuery.sizeOf(context).width - 24;
    final target = isNumberPadLayout ? 360.0 : 760.0;
    return available < target ? available : target;
  }

  double keyboardViewportHeightFor(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1000) return 20;
    return isNumberPadLayout ? 24 : 40;
  }

  @override
  void attach(TextInputClient client, TextInputConfiguration configuration) {
    _client = client;
    _configuration = configuration;
    _value = client.currentTextEditingValue ?? TextEditingValue.empty;
    _layoutMode = _KeyboardLayoutMode.auto;
    _shiftEnabled = false;
    notifyListeners();
  }

  @override
  void detach(TextInputClient client) {
    if (!identical(_client, client)) return;
    _client = null;
    _configuration = const TextInputConfiguration();
    _value = TextEditingValue.empty;
    _visible = false;
    _shiftEnabled = false;
    _layoutMode = _KeyboardLayoutMode.auto;
    notifyListeners();
  }

  @override
  void show() {
    if (_client == null) return;
    _visible = true;
    notifyListeners();
  }

  @override
  void hide() {
    if (!_visible) return;
    _visible = false;
    notifyListeners();
  }

  @override
  void updateConfig(TextInputConfiguration configuration) {
    _configuration = configuration;
    notifyListeners();
  }

  @override
  void setEditingState(TextEditingValue value) {
    _value = value;
    notifyListeners();
  }

  void toggleShift() {
    _shiftEnabled = !_shiftEnabled;
    notifyListeners();
  }

  void showAlphaLayout() {
    _layoutMode = _KeyboardLayoutMode.alpha;
    notifyListeners();
  }

  void showNumericLayout() {
    _layoutMode = _KeyboardLayoutMode.numeric;
    notifyListeners();
  }

  void dismiss() {
    hide();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void clear() {
    _commitValue(
      const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      ),
    );
  }

  void backspace() {
    if (_client == null) return;
    final sel = _normalizedSelection(_value);
    if (!sel.isCollapsed) {
      final t = _value.text.replaceRange(sel.start, sel.end, '');
      _commitValue(TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: sel.start),
      ));
      return;
    }
    if (sel.start <= 0) return;
    final ri = sel.start - 1;
    final t = _value.text.replaceRange(ri, sel.start, '');
    _commitValue(TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: ri),
    ));
  }

  void insertText(String rawText) {
    if (_client == null) return;
    final sel = _normalizedSelection(_value);
    final text = _applyCase(rawText);
    final newText = _value.text.replaceRange(sel.start, sel.end, text);
    _commitValue(TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + text.length),
    ));
  }

  void submit() {
    final client = _client;
    if (client == null) return;
    if (isMultiline) {
      TextInput.finishAutofillContext(shouldSave: true);
      dismiss();
      return;
    }
    final action = _configuration.inputAction;
    client.performAction(action);
    if (action == TextInputAction.next || action == TextInputAction.previous) {
      return;
    }
    TextInput.finishAutofillContext(shouldSave: true);
    dismiss();
  }

  TextSelection _normalizedSelection(TextEditingValue v) {
    final s = v.selection;
    if (!s.isValid) return TextSelection.collapsed(offset: v.text.length);
    return TextSelection(
      baseOffset: s.start.clamp(0, v.text.length).toInt(),
      extentOffset: s.end.clamp(0, v.text.length).toInt(),
    );
  }

  String _applyCase(String raw) {
    if (raw.isEmpty) return raw;
    if (!RegExp(r'^[a-zA-Z]$').hasMatch(raw)) return raw;
    return _shiftEnabled ? raw.toUpperCase() : raw.toLowerCase();
  }

  void _commitValue(TextEditingValue v) {
    _value = v.copyWith(composing: TextRange.empty);
    TextInput.updateEditingValue(_value);
    notifyListeners();
  }
}

// ── Panel principal ───────────────────────────────────────────────────────────

class _TouchKeyboardPanel extends StatelessWidget {
  const _TouchKeyboardPanel({required this.controller});

  final _TouchKeyboardController controller;

  @override
  Widget build(BuildContext context) {
    final visible = controller.visible;
    final height = controller.keyboardHeightFor(context);
    final maxWidth = controller.keyboardMaxWidthFor(context);
    final position = controller.keyboardPosition;
    final screenSize = MediaQuery.sizeOf(context);

    return IgnorePointer(
      ignoring: !visible,
      child: GestureDetector(
        onPanUpdate: (d) =>
            controller.setKeyboardPosition(position + d.delta),
        child: Stack(
          children: [
            Positioned(
              left: position.dx.clamp(0.0, screenSize.width - maxWidth - 24),
              top: position.dy.clamp(-height, screenSize.height - 12),
              child: TextFieldTapRegion(
                child: Focus(
                  canRequestFocus: false,
                  skipTraversal: true,
                  descendantsAreFocusable: false,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    offset: visible ? Offset.zero : const Offset(0, 1),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 120),
                      opacity: visible ? 1 : 0,
                      child: Container(
                        width: maxWidth,
                        height: height,
                        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        decoration: BoxDecoration(
                          color: _KB.bg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _KB.border, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.14),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _KeyboardHeader(controller: controller),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                child: _KeyboardBody(controller: controller),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _KeyboardHeader extends StatelessWidget {
  const _KeyboardHeader({required this.controller});

  final _TouchKeyboardController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      decoration: const BoxDecoration(
        color: _KB.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: _KB.divider, width: 1)),
      ),
      child: Row(
        children: [
          // ── Drag hint ────────────────────────────────────────────────
          Icon(Icons.drag_indicator_rounded,
              size: 18, color: _KB.secondaryText.withOpacity(0.45)),
          const SizedBox(width: 6),
          // ── Mode switch : ABC | 123 (symbols supprimé) ───────────────
          _KeyboardModeSwitch(controller: controller),
          const Spacer(),
          // ── Bouton fermer ────────────────────────────────────────────
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              canRequestFocus: false,
              onTap: controller.dismiss,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _KB.secondaryBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.keyboard_hide_rounded,
                    size: 18, color: _KB.secondaryText),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mode switch (ABC / 123 uniquement) ───────────────────────────────────────

class _KeyboardModeSwitch extends StatelessWidget {
  const _KeyboardModeSwitch({required this.controller});

  final _TouchKeyboardController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _KB.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _KB.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            label: 'ABC',
            selected: controller.isAlphaLayout,
            onTap: controller.showAlphaLayout,
          ),
          const SizedBox(width: 4),
          _ModeButton(
            label: '123',
            selected: controller.isNumberPadLayout,
            onTap: controller.showNumericLayout,
          ),
        ],
      ),
    );
  }
}

// ── Body dispatcher ───────────────────────────────────────────────────────────

class _KeyboardBody extends StatelessWidget {
  const _KeyboardBody({required this.controller});

  final _TouchKeyboardController controller;

  @override
  Widget build(BuildContext context) {
    return controller.isNumberPadLayout
        ? _NumericKeyboard(controller: controller)
        : _AlphaKeyboard(controller: controller);
  }
}

// ── Clavier alphabétique ──────────────────────────────────────────────────────

class _AlphaKeyboard extends StatelessWidget {
  const _AlphaKeyboard({required this.controller});

  final _TouchKeyboardController controller;

  String _d(String k) =>
      controller.shiftEnabled ? k.toUpperCase() : k.toLowerCase();

  List<String> get _specialKeys {
    if (controller.isEmailLayout) return ['@', '.', '_', '-', '+', '/', ':', '.com'];
    if (controller.isUrlLayout) return ['/', '.', ':', '-', '_', '?', '&', '='];
    return ['é', 'è', 'à', 'ç', '\'', '-', ',', '.'];
  }

  @override
  Widget build(BuildContext context) {
    const ts = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: _KB.keyText,
    );

    return Column(
      children: [
        // Rangée 1 : A Z E R T Y U I O P
        Expanded(
          child: _KeyRow(
            keys: 'a z e r t y u i o p'
                .split(' ')
                .map((k) => _KeySpec.text(_d(k)))
                .toList(),
            onTextTap: controller.insertText,
            textStyle: ts,
          ),
        ),
        const SizedBox(height: 5),
        // Rangée 2 : Q S D F G H J K L M
        Expanded(
          child: _KeyRow(
            keys: 'q s d f g h j k l m'
                .split(' ')
                .map((k) => _KeySpec.text(_d(k)))
                .toList(),
            onTextTap: controller.insertText,
            textStyle: ts,
          ),
        ),
        const SizedBox(height: 5),
        // Rangée 3 : ⇧  W X C V B N  ⌫
        Expanded(
          child: _KeyRow(
            keys: [
              _KeySpec.icon(
                Icons.keyboard_capslock_rounded,
                onTap: controller.toggleShift,
                flex: 2,
                selected: controller.shiftEnabled,
              ),
              for (final k in ['w', 'x', 'c', 'v', 'b', 'n'])
                _KeySpec.text(_d(k)),
              _KeySpec.icon(
                Icons.backspace_outlined,
                onTap: controller.backspace,
                flex: 2,
              ),
            ],
            onTextTap: controller.insertText,
            textStyle: ts,
          ),
        ),
        const SizedBox(height: 5),
        // Rangée 4 : caractères spéciaux
        Expanded(
          child: _KeyRow(
            keys: _specialKeys.map((k) => _KeySpec.text(k)).toList() +
                [
                  if (controller.isMultiline)
                    _KeySpec.label(
                      'Entrer',
                      onTap: () => controller.insertText('\n'),
                      flex: 2,
                    ),
                ],
            onTextTap: controller.insertText,
            textStyle: ts.copyWith(fontSize: 13),
          ),
        ),
        const SizedBox(height: 5),
        // Rangée 5 : Effacer | Espace | Valider
        Expanded(
          child: _KeyRow(
            keys: [
              _KeySpec.label('Effacer', onTap: controller.clear, flex: 2, secondary: true),
              _KeySpec.label(
                'Espace',
                onTap: () => controller.insertText(' '),
                flex: 4,
                secondary: true,
              ),
              _KeySpec.label(
                controller.actionLabel,
                onTap: controller.submit,
                flex: 2,
                accent: true,
              ),
            ],
            onTextTap: controller.insertText,
            textStyle: ts,
          ),
        ),
      ],
    );
  }
}

// ── Clavier numérique ─────────────────────────────────────────────────────────

class _NumericKeyboard extends StatelessWidget {
  const _NumericKeyboard({required this.controller});

  final _TouchKeyboardController controller;

  @override
  Widget build(BuildContext context) {
    const ts = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: _KB.keyText,
    );

    return Column(
      children: [
        // 1  2  3  ⌫
        Expanded(
          child: _KeyRow(
            keys: [
              _KeySpec.text('1'), _KeySpec.text('2'), _KeySpec.text('3'),
              _KeySpec.icon(Icons.backspace_outlined, onTap: controller.backspace),
            ],
            onTextTap: controller.insertText,
            textStyle: ts,
          ),
        ),
        const SizedBox(height: 6),
        // 4  5  6  Effacer
        Expanded(
          child: _KeyRow(
            keys: [
              _KeySpec.text('4'), _KeySpec.text('5'), _KeySpec.text('6'),
              _KeySpec.label('X', onTap: controller.clear, secondary: true),
            ],
            onTextTap: controller.insertText,
            textStyle: ts,
          ),
        ),
        const SizedBox(height: 6),
        // 7  8  9  [. ou *]
        Expanded(
          child: _KeyRow(
            keys: [
              _KeySpec.text('7'), _KeySpec.text('8'), _KeySpec.text('9'),
              _rightKey == null ? _KeySpec.empty() : _KeySpec.text(_rightKey!),
            ],
            onTextTap: controller.insertText,
            textStyle: ts,
          ),
        ),
        const SizedBox(height: 6),
        // +/- ou 00  0  [. ou #]  Valider
        Expanded(
          child: _KeyRow(
            keys: [
              _KeySpec.text(_leftKey),
              _KeySpec.text('0'),
              _bottomKey == null ? _KeySpec.empty() : _KeySpec.text(_bottomKey!),
              _KeySpec.label(
                controller.actionLabel,
                onTap: controller.submit,
                accent: true,
              ),
            ],
            onTextTap: controller.insertText,
            textStyle: ts,
          ),
        ),
      ],
    );
  }

  String get _leftKey {
    if (controller.isPhoneLayout) return '+';
    if (controller.isSignedNumber) return '-';
    return '00';
  }

  String? get _bottomKey {
    if (controller.isPhoneLayout) return '#';
    if (controller.isDecimalNumber) return '.';
    return null;
  }

  String? get _rightKey {
    if (controller.isDecimalNumber) return '.';
    if (controller.isPhoneLayout) return '*';
    return null;
  }
}

// ── Mode button ───────────────────────────────────────────────────────────────

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        canRequestFocus: false,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? _KB.accentBg : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected ? _KB.accentText : _KB.secondaryText,
              decoration: TextDecoration.none,
              decorationColor: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

// ── KeyRow ────────────────────────────────────────────────────────────────────

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.keys,
    required this.onTextTap,
    required this.textStyle,
  });

  final List<_KeySpec> keys;
  final ValueChanged<String> onTextTap;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < keys.length; i++) ...[
          Expanded(
            flex: keys[i].flex,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: _KeyboardKey(
                  spec: keys[i],
                  onTextTap: onTextTap,
                  textStyle: textStyle,
                ),
              ),
            ),
          ),
          if (i != keys.length - 1) const SizedBox(width: 5),
        ],
      ],
    );
  }
}

// ── Key ───────────────────────────────────────────────────────────────────────

class _KeyboardKey extends StatelessWidget {
  const _KeyboardKey({
    required this.spec,
    required this.onTextTap,
    required this.textStyle,
  });

  final _KeySpec spec;
  final ValueChanged<String> onTextTap;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final isEmpty =
        spec.text == null && spec.label == null && spec.icon == null;
    if (isEmpty) return const SizedBox.expand();

    // Couleurs selon rôle
    final Color bg;
    final Color fg;
    final Color borderColor;

    if (spec.accent) {
      bg = _KB.accentBg;
      fg = _KB.accentText;
      borderColor = _KB.accentBg;
    } else if (spec.selected) {
      bg = _KB.selectedBg;
      fg = _KB.selectedText;
      borderColor = _KB.selectedText.withOpacity(0.4);
    } else if (spec.secondary) {
      bg = _KB.secondaryBg;
      fg = _KB.secondaryText;
      borderColor = _KB.secondaryBg;
    } else {
      bg = _KB.keyBg;
      fg = _KB.keyText;
      borderColor = _KB.keyBorder;
    }

    final onPressed =
        spec.onTap ?? (spec.text != null ? () => onTextTap(spec.text!) : null);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        canRequestFocus: false,
        borderRadius: BorderRadius.circular(9),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: spec.accent || spec.secondary
                ? null
                : [
                    BoxShadow(
                      color: _KB.keyShadow,
                      blurRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Center(
            child: spec.icon != null
                ? Icon(spec.icon, color: fg, size: 18)
                : Text(
                    spec.label ?? spec.text ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle.copyWith(
                      color: fg,
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── KeySpec ───────────────────────────────────────────────────────────────────

class _KeySpec {
  const _KeySpec({
    this.text,
    this.label,
    this.icon,
    this.onTap,
    this.flex = 1,
    this.accent = false,
    this.selected = false,
    this.secondary = false,
  });

  factory _KeySpec.text(String text, {int flex = 1}) =>
      _KeySpec(text: text, flex: flex);

  factory _KeySpec.label(
    String label, {
    required VoidCallback onTap,
    int flex = 1,
    bool accent = false,
    bool secondary = false,
  }) =>
      _KeySpec(
          label: label,
          onTap: onTap,
          flex: flex,
          accent: accent,
          secondary: secondary);

  factory _KeySpec.icon(
    IconData icon, {
    required VoidCallback onTap,
    int flex = 1,
    bool selected = false,
  }) =>
      _KeySpec(icon: icon, onTap: onTap, flex: flex, selected: selected);

  factory _KeySpec.empty({int flex = 1}) => _KeySpec(flex: flex);

  final String? text;
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final int flex;
  final bool accent;
  final bool selected;
  final bool secondary; // ← nouveau rôle : Effacer, Espace, etc.
}