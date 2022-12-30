library autocomplete_textfield;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef AutoCompleteOverlayItemBuilder<T> = Widget Function(
    BuildContext context, T suggestion);

typedef Filter<T> = bool Function(T suggestion, String query);

typedef InputEventCallback<T> = Function(T data);

typedef StringCallback = Function(String data);

class AutoCompleteTextField<T> extends StatefulWidget {
  final List<T> suggestions;
  final Filter<T>? itemFilter;
  final Comparator<T>? itemSorter;
  final StringCallback? textChanged, textSubmitted;
  final ValueSetter<bool>? onFocusChanged;
  final InputEventCallback<T>? itemSubmitted;
  final AutoCompleteOverlayItemBuilder<T>? itemBuilder;
  final int suggestionsAmount;
  final bool submitOnSuggestionTap, clearOnSubmit, unFocusOnItemSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final int minLength;
  final InputDecoration decoration;
  final TextStyle? style;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Color? cursorColor;
  final double? cursorWidth;
  final Radius? cursorRadius;
  final bool? showCursor;
  final bool autofocus;
  final bool autocorrect;

  const AutoCompleteTextField({
    // Callback on item selected, this is the item selected of type <T>
    required this.itemSubmitted,
    //GlobalKey used to enable addSuggestion etc
    required GlobalKey<AutoCompleteTextFieldState<T>> key,
    // Suggestions that will be displayed
    required this.suggestions,
    // Callback to build each item, return a Widget
    required this.itemBuilder,
    // Callback to sort items in the form (a of type <T>, b of type <T>)
    required this.itemSorter,
    // Callback to filter item: return true or false depending on input text
    required this.itemFilter,
    this.inputFormatters,
    this.style,
    this.decoration = const InputDecoration(),
    // Callback on input text changed, this is a string
    this.textChanged,
    // Callback on input text submitted, this is also a string
    this.textSubmitted,
    this.onFocusChanged,
    this.cursorRadius,
    this.cursorWidth,
    this.cursorColor,
    this.showCursor,
    this.keyboardType = TextInputType.text,
    // The amount of suggestions to show, larger values may result in them going off screen
    this.suggestionsAmount = 5,
    // Call textSubmitted on suggestion tap, itemSubmitted will be called no matter what
    this.submitOnSuggestionTap = true,
    // Clear autoCompleteTextField on submit
    this.clearOnSubmit = true,
    this.textInputAction = TextInputAction.done,
    this.textCapitalization = TextCapitalization.sentences,
    // Set the autocorrection on the internal text input field
    this.autocorrect = false,
    this.minLength = 1,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.unFocusOnItemSubmitted = true
  }) : super(key: key);

  @override
  GlobalKey<AutoCompleteTextFieldState<T>> get key {
    return super.key! as GlobalKey<AutoCompleteTextFieldState<T>>;
  }

  void clear() => key.currentState!.clear();

  void addSuggestion(T suggestion) =>
      key.currentState!.addSuggestion(suggestion);

  void removeSuggestion(T suggestion) =>
      key.currentState!.removeSuggestion(suggestion);

  void updateSuggestions(List<T> suggestions) =>
      key.currentState!.updateSuggestions(suggestions);

  void triggerSubmitted() => key.currentState!.triggerSubmitted();

  void updateDecoration(
      {InputDecoration? decoration,
        List<TextInputFormatter>? inputFormatters,
        TextCapitalization? textCapitalization,
        TextStyle? style,
        TextInputType? keyboardType,
        TextInputAction? textInputAction}) =>
      key.currentState!.updateDecoration(decoration, inputFormatters,
          textCapitalization, style, keyboardType, textInputAction);

  TextField? get textField => key.currentState!.textField;

  @override
  State<StatefulWidget> createState() => AutoCompleteTextFieldState<T>();
}

class AutoCompleteTextFieldState<T> extends State<AutoCompleteTextField<T>> {
  final LayerLink _layerLink = LayerLink();

  TextField? textField;
  String currentText = "";
  List<T>? filteredSuggestions;
  OverlayEntry? listSuggestionsEntry;

  @override
  void initState() {
    textField = TextField(
      inputFormatters: widget.inputFormatters,
      textCapitalization: widget.textCapitalization,
      decoration: widget.decoration,
      style: widget.style,
      cursorColor: widget.cursorColor ?? Colors.black,
      showCursor: widget.showCursor ?? true,
      cursorWidth: widget.cursorWidth ?? 1,
      cursorRadius: widget.cursorRadius ?? const Radius.circular(2.0),
      keyboardType: widget.keyboardType,
      focusNode: widget.focusNode ?? FocusNode(),
      autofocus: widget.autofocus,
      controller: widget.controller ?? TextEditingController(),
      textInputAction: widget.textInputAction,
      autocorrect: widget.autocorrect,
      onChanged: (newText) {
        currentText = newText;
        updateOverlay(newText);

        if (widget.textChanged != null) {
          widget.textChanged!(newText);
        }
      },
      onTap: () {
        updateOverlay(currentText);
      },
      onSubmitted: (submittedText) =>
          triggerSubmitted(submittedText: submittedText),
    );

    if (widget.controller != null) {
      currentText = widget.controller!.text;
    }

    textField!.focusNode!.addListener(() {
      if (widget.onFocusChanged != null) {
        widget.onFocusChanged!(textField!.focusNode!.hasFocus);
      }

      if (!textField!.focusNode!.hasFocus) {
        filteredSuggestions = [];
        updateOverlay();
      } else if (currentText != "") {
        updateOverlay(currentText);
      }
    });
    super.initState();
  }

  void updateDecoration(
      InputDecoration? decoration,
      List<TextInputFormatter>? inputFormatters,
      TextCapitalization? textCapitalization,
      TextStyle? style,
      TextInputType? keyboardType,
      TextInputAction? textInputAction) {
    if (decoration != null) {
      decoration = decoration;
    }

    if (inputFormatters != null) {
      inputFormatters = inputFormatters;
    }

    if (textCapitalization != null) {
      textCapitalization = textCapitalization;
    }

    if (style != null) {
      style = style;
    }

    if (keyboardType != null) {
      keyboardType = keyboardType;
    }

    if (textInputAction != null) {
      textInputAction = textInputAction;
    }

    setState(() {
      textField = TextField(
        inputFormatters: inputFormatters,
        textCapitalization: widget.textCapitalization,
        decoration: decoration,
        style: style,
        keyboardType: keyboardType,
        focusNode: widget.focusNode ?? FocusNode(),
        autofocus: widget.autofocus,
        controller: widget.controller ?? TextEditingController(),
        textInputAction: textInputAction,
        onChanged: (newText) {
          currentText = newText;
          updateOverlay(newText);

          if (widget.textChanged != null) {
            widget.textChanged!(newText);
          }
        },
        onTap: () {
          updateOverlay(currentText);
        },
        onSubmitted: (submittedText) =>
            triggerSubmitted(submittedText: submittedText),
      );
    });
  }

  void triggerSubmitted({submittedText}) {
    submittedText == null
        ? widget.textSubmitted!(currentText)
        : widget.textSubmitted!(submittedText);

    if (widget.clearOnSubmit) {
      clear();
    }
  }

  void clear() {
    textField!.controller!.clear();
    currentText = "";
    updateOverlay();
  }

  void addSuggestion(T suggestion) {
    widget.suggestions.add(suggestion);
    updateOverlay(currentText);
  }

  void removeSuggestion(T suggestion) {
    widget.suggestions.contains(suggestion)
        ? widget.suggestions.remove(suggestion)
        : throw "List does not contain suggestion and therefore cannot be removed";
    updateOverlay(currentText);
  }

  void updateSuggestions(List<T> suggestions) {
    widget.suggestions.clear();
    widget.suggestions.addAll(suggestions);
    updateOverlay(currentText);
  }

  void updateOverlay([String? query]) {
    if (listSuggestionsEntry == null && filteredSuggestions != null) {
      final Size textFieldSize = (context.findRenderObject() as RenderBox).size;
      final width = textFieldSize.width;
      final height = textFieldSize.height;
      listSuggestionsEntry = OverlayEntry(builder: (context) {
        return Positioned(
            width: width,
            child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0.0, height),
                child: SizedBox(
                    width: width,
                    child: Card(
                        child: Column(
                          children: filteredSuggestions!.map((suggestion) {
                            return Row(children: [
                              Expanded(
                                  child: InkWell(
                                      child: widget.itemBuilder!(context, suggestion),
                                      onTap: () {
                                        if (!mounted) return;
                                        setState(() {
                                          if (widget.submitOnSuggestionTap) {
                                            String newText = suggestion.toString();
                                            textField!.controller!.text = newText;
                                            if (widget.unFocusOnItemSubmitted) {
                                              textField!.focusNode!.unfocus();
                                            }
                                            widget.itemSubmitted!(suggestion);
                                            if (widget.clearOnSubmit) {
                                              clear();
                                            }
                                          } else {
                                            String newText = suggestion.toString();
                                            textField!.controller!.text = newText;
                                            widget.textChanged!(newText);
                                          }
                                        });
                                      }))
                            ]);
                          }).toList(),
                        )))));
      });
      Overlay.of(context)!.insert(listSuggestionsEntry!);
    }

    filteredSuggestions = getSuggestions(
        widget.suggestions, widget.itemSorter, widget.itemFilter, widget.suggestionsAmount, query);

    listSuggestionsEntry?.markNeedsBuild();
  }

  List<T> getSuggestions(List<T> suggestions, Comparator<T>? sorter,
      Filter<T>? filter, int maxAmount, String? query) {
    if (null == query || query.length < widget.minLength) {
      return [];
    }

    suggestions = suggestions.where((item) => filter!(item, query)).toList();
    suggestions.sort(sorter);
    if (suggestions.length > maxAmount) {
      suggestions = suggestions.sublist(0, maxAmount);
    }
    return suggestions;
  }

  @override
  void dispose() {
    // if we created our own focus node and controller, dispose of them
    // otherwise, let the caller dispose of their own instances
    if (widget.focusNode == null) {
      textField!.focusNode!.dispose();
    }
    if (widget.controller == null) {
      textField!.controller!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(link: _layerLink, child: textField);
  }
}

class SimpleAutoCompleteTextField extends AutoCompleteTextField<String> {

  SimpleAutoCompleteTextField({
    super.style,
    super.decoration,
    super.onFocusChanged,
    super.textChanged,
    super.textSubmitted,
    super.minLength = 1,
    super.controller,
    super.focusNode,
    super.autofocus,
    super.cursorColor,
    super.cursorWidth,
    super.cursorRadius,
    super.showCursor,
    super.keyboardType,
    required super.key,
    required super.suggestions,
    super.suggestionsAmount,
    super.submitOnSuggestionTap,
    super.clearOnSubmit,
    super.textInputAction,
    super.textCapitalization,
  }) : super(
    itemSubmitted: textSubmitted,
    itemBuilder: (context, item) {
      return Padding(padding: const EdgeInsets.all(8.0), child: Text(item));
    },
    itemSorter: (a, b) {
      return a.compareTo(b);
    },
    itemFilter: (item, query) {
      final regex = RegExp(query, caseSensitive: false);
      return regex.hasMatch(item.toLowerCase());
    },
  );

  @override
  State<StatefulWidget> createState() => AutoCompleteTextFieldState<String>();
}
