public class BuffEffect implements EffectPolicy {

    private final String stat;      // "strength", "agility", "intelligence"
    private final double multiplier;

    public BuffEffect(String stat, double multiplier) {
        this.stat = stat;
        this.multiplier = multiplier;
    }

    @Override
    public void apply(Character character, Item item) {
        int bonus = (int) (item.getBaseValue() * multiplier);
        switch (stat.toLowerCase()) {
            case "strength":
                character.setStrength(character.getStrength() + bonus);
                break;
            case "agility":
                character.setAgility(character.getAgility() + bonus);
                break;
            case "intelligence":
                character.setIntelligence(character.getIntelligence() + bonus);
                break;
            default:
                System.out.println("Неизвестная характеристика: " + stat);
                return;
        }
        System.out.println("Предмет '" + item.getName() + "' дал +" + bonus
                + " к " + stat + " персонажу '" + character.getName() + "'.");
    }
}