enum LivenessAction {
  blink('Blink twice'),
  smile('Smile naturally'),
  turnHeadLeft('Turn head left'),
  turnHeadRight('Turn head right');

  const LivenessAction(this.instruction);

  final String instruction;
}
