public class ItemAbilitySource implements AbilitySource {

    private final double coefficient;

    public ItemAbilitySource(double coefficient) {
        this.coefficient = coefficient;
    }

    @Override
    public double getAbilityPower(Character character) {
        double totalValue = character.getInventory().getTotalValue();
        return totalValue * coefficient;
    }

    @Override
    public String toString() {
        return "ItemAbilitySource{coefficient=" + coefficient + "}";
    }
}