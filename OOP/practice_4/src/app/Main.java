package app;

import core.BossCharacter;
import core.Character;
import core.GameCoreService;

public class Main {
    public static void main(String[] args) {

        System.out.println("");
        System.out.println("Game: " + Character.GAME_NAME);
        System.out.println("");

        System.out.println("\nCreating characters");
        Character warrior = new Character("Warrior", 100, 20, 1);
        Character mage = new Character("Mage", 80, 30, 1);
        BossCharacter dragon = new BossCharacter("Dragon", 500, 50, 10);

        System.out.println(warrior);
        System.out.println(mage);
        System.out.println(dragon);
        System.out.println("Total created: " + Character.getCreatedCharacters());

        System.out.println("\nCombat: dealing damage");
        warrior.takeDamage(30);
        System.out.println("Warrior health: " + warrior.getHealth());

        mage.takeDamage(50);
        System.out.println("Mage health: " + mage.getHealth());

        System.out.println("\nHealing");
        warrior.heal(20);
        System.out.println("Warrior health after heal: " + warrior.getHealth());

        System.out.println("\nKilling mage");
        mage.takeDamage(100); //dead
        System.out.println("Mage alive? " + mage.isAlive());
        System.out.println("Mage health: " + mage.getHealth());

        System.out.println("\nCore service: revive");
        GameCoreService coreService = new GameCoreService();
        coreService.revive(mage);
        System.out.println("Mage alive after revive? " + mage.isAlive());
        System.out.println("Mage health after revive: " + mage.getHealth());

        coreService.applyTick(warrior);
        coreService.applyTick(mage);

        coreService.balance(warrior);

        coreService.printCoreDebug(warrior);

        System.out.println("\nBoss: rage mechanics");
        dragon.gainRage(40);
        dragon.gainRage(30);
        dragon.unleashRage();

        dragon.gainRage(50);
        dragon.unleashRage();
        System.out.println(dragon);

        System.out.println("\n");
        System.out.println("Total characters created: " + Character.getCreatedCharacters());
        System.out.println("Game: " + Character.GAME_NAME);
        System.out.println("");

        

        // Доступ к private полям
        // System.out.println(warrior.health);   // health has private access in Character
        // System.out.println(warrior.damage);   // damage has private access in Character

        // // Вызов private методов
        // warrior.die();                        // die() has private access in Character
        // warrior.logPrivate("test");           // logPrivate() has private access in Character

        // Доступ к package-private полю из другого пакета
        // System.out.println(warrior.alive);    // alive is not public; cannot be accessed from outside package

        // Вызов package-private методов из другого пакета
        // warrior.reviveForCore(100);           // reviveForCore() is not public
        // warrior.setDamageForCore(999);        // setDamageForCore() is not public

        // Вызов protected методов из другого пакета
        // warrior.addLevel(5);                  // addLevel() has protected access
        // warrior.empower(99);                  // empower() has protected access

        // Доступ к private static полю
        // System.out.println(Character.createdCharacters); // createdCharacters has private access

        // Доступ к package-private static полю
        // System.out.println(Character.coreEvents);        // coreEvents is not public; cannot be accessed from outside package
    }
}