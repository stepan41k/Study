import java.util.ArrayList;
import java.util.List;

/**
 * Character — игровой персонаж, владелец инвентаря (композиция).
 * Инвентарь создаётся в конструкторе и не может быть заменён.
 * AbilitySource подключаются через агрегацию.
 */
public class Character {

    private final String id;
    private final String name;
    private final Inventory inventory;

    private int strength = 10;
    private int agility = 10;
    private int intelligence = 10;

    private final List<AbilitySource> abilitySources = new ArrayList<>();

    public Character(String id, String name) {
        if (id == null || id.isBlank()) {
            throw new IllegalArgumentException("ID персонажа не может быть пустым.");
        }
        if (name == null || name.isBlank()) {
            throw new IllegalArgumentException("Имя персонажа не может быть пустым.");
        }
        this.id = id;
        this.name = name;
        this.inventory = new Inventory();
    }

    public void addItem(Item item, int quantity) {
        inventory.addItem(item, quantity);
    }

    public boolean removeItem(String itemId) {
        return inventory.removeItem(itemId);
    }

    public void changeQuantity(String itemId, int newQuantity) {
        inventory.changeQuantity(itemId, newQuantity);
    }

    public void printInventory() {
        System.out.println("Инвентарь персонажа '" + name + "':");
        inventory.printInventory();
    }

    public int getStrength() {
        return strength;
    }

    public void setStrength(int strength) {
        this.strength = strength;
    }

    public int getAgility() {
        return agility;
    }

    public void setAgility(int agility) {
        this.agility = agility;
    }

    public int getIntelligence() {
        return intelligence;
    }

    public void setIntelligence(int intelligence) {
        this.intelligence = intelligence;
    }

    public void addAbilitySource(AbilitySource source) {
        if (source != null) {
            abilitySources.add(source);
        }
    }

    public void removeAbilitySource(AbilitySource source) {
        abilitySources.remove(source);
    }

    public double getTotalAbilityPower() {
        double total = 0;
        for (AbilitySource src : abilitySources) {
            total += src.getAbilityPower(this);
        }
        return total;
    }

    public String getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public Inventory getInventory() {
        return inventory;
    }

    @Override
    public String toString() {
        return "Character{id='" + id + "', name='" + name
                + "', STR=" + strength + ", AGI=" + agility + ", INT=" + intelligence
                + ", abilityPower=" + getTotalAbilityPower() + "}";
    }
}