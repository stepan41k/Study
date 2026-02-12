public class SkillAbilitySource implements AbilitySource {

    private final double coefficient;

    public SkillAbilitySource(double coefficient) {
        this.coefficient = coefficient;
    }

    @Override
    public double getAbilityPower(Character character) {
        int totalStats = character.getStrength() + character.getAgility() + character.getIntelligence();
        return totalStats * coefficient;
    }

    @Override
    public String toString() {
        return "SkillAbilitySource{coefficient=" + coefficient + "}";
    }
}