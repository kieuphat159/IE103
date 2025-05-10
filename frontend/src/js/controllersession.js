class ControllerSession {
    constructor() {
        this.userKey = 'user';
    }

    getUser() {
        const userData = localStorage.getItem(this.userKey);
        return userData ? JSON.parse(userData) : null;
    }

    isLoggedInAsController() {
        const user = this.getUser();
        return user && user.isController;
    }

    setUser(userData) {
        localStorage.setItem(this.userKey, JSON.stringify(userData));
    }

    updateUserInterface() {
        const user = this.getUser();
        if (user && user.isController) {
            const userInfoElement = document.getElementById('userInfo');
            if (userInfoElement) {
                userInfoElement.textContent = `Chào ${user.ten || 'Nhân viên kiểm soát'}`;
            }
            const userCircleElement = document.getElementById('userCircle');
            if (userCircleElement) {
                userCircleElement.textContent = user.ten ? user.ten.charAt(0).toUpperCase() : 'NV';
                userCircleElement.title = user.ten || 'Nhân viên kiểm soát';
            }
        } else {
            window.location.href = 'login.html';
        }
    }

    logout() {
        localStorage.removeItem(this.userKey);
        window.location.href = 'login.html';
    }
}

const controllerSession = new ControllerSession();
export default controllerSession;