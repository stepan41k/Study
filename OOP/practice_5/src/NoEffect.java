public class NoEffect implements EffectPolicy {

    @Override
    public void apply(Character character, Item item) {
        System.out.println("Предмет '" + item.getName() + "' не даёт эффекта персонажу '"
                + character.getName() + "'.");
    }
}