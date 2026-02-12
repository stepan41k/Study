package src.core;

public class Character {

    // === Поля экземпляра ===
    private String name;
    private int health;
    private int damage;
    protected int level;
    boolean alive; // package-private

    // === Статические поля ===
    public static final String GAME_NAME = "Arena";
    private static int createdCharacters = 0;
    static int coreEvents = 0; // package-private

    // === Конструктор ===
    public Character(String name, int health, int damage, int level) {
        this.name = name;
        this.health = health;
        this.damage = damage;
        this.level = level;
        this.alive = true;
        createdCharacters++;
    }

    // === Публичные методы (API для приложения) ===

    public String getName() {
        return name;
    }

    public int getHealth() {
        return health;
    }

    public int getLevel() {
        return level;
    }

    public boolean isAlive() {
        return alive;
    }

    public void heal(int amount) {
        if (amount > 0 && alive) {
            health += amount;
            logPrivate(name + " healed for " + amount + ". Health: " + health);
        }
    }

    public void takeDamage(int amount) {
        if (amount > 0 && alive) {
            health -= amount;
            logPrivate(name + " took " + amount + " damage. Health: " + health);
            if (health <= 0) {
                die();
            }
        }
    }

    public static int getCreatedCharacters() {
        return createdCharacters;
    }

    // === Private методы (скрытая логика) ===

    private void die() {
        alive = false;
        health = 0;
        logPrivate(name + " has died!");
    }

    private void logPrivate(String msg) {
        System.out.println("[LOG] " + msg);
    }

    // === Package-private методы (для ядра игры) ===

    void reviveForCore(int hp) {
        alive = true;
        health = hp;
        logPrivate(name + " revived by core with " + hp + " HP.");
    }

    void setDamageForCore(int newDamage) {
        this.damage = newDamage;
        logPrivate(name + " damage set to " + newDamage + " by core.");
    }

    // === Protected методы (для наследников) ===

    protected void addLevel(int delta) {
        if (delta > 0) {
            level += delta;
            logPrivate(name + " leveled up by " + delta + ". Level: " + level);
        }
    }

    protected void empower(int bonusDamage) {
        if (bonusDamage > 0) {
            damage += bonusDamage;
            logPrivate(name + " empowered! Damage: " + damage);
        }
    }

    // === toString для удобного вывода ===
    @Override
    public String toString() {
        return "Character{name='" + name + "', health=" + health +
               ", damage=" + damage + ", level=" + level +
               ", alive=" + alive + "}";
    }
}