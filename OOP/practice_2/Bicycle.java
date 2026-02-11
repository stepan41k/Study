public class Bicycle extends AbstractVehicle {

    public Bicycle(String model, double speed) {
        super(model, speed);
    }

    @Override
    public void start() {
        System.out.println("Начинаю крутить педали");
    }

    @Override
    public void stop() {
        System.out.println("Перестаю крутить педали");
    }
}