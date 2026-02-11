package src.core;

public class BossCharacter extends Character {

    private int rage; // 0..100

    public BossCharacter(String name, int health, int damage, int level) {
        super(name, health, damage, level);
        this.rage = 0;
    }

    public void gainRage(int amount) {
        if (amount > 0) {
            rage += amount;
            if (rage > 100) {
                rage = 100;
            }
            System.out.println("[BOSS] " + getName() + " gained " + amount +
                               " rage. Rage: " + rage);
        }
    }

    public void unleashRage() {
        if (rage >= 100) {
            System.out.println("[BOSS] " + getName() + " UNLEASHES RAGE!");
            empower(rage / 2);  // protected метод из Character
            addLevel(1);        // protected метод из Character
            rage = 0;
        } else {
            System.out.println("[BOSS] " + getName() +
                               " not enough rage (" + rage + "/100).");
        }
    }

    public int getRage() {
        return rage;
    }

    @Override
    public String toString() {
        return "BossCharacter{name='" + getName() + "', health=" + getHealth() +
               ", level=" + getLevel() + ", rage=" + rage +
               ", alive=" + isAlive() + "}";
    }
}