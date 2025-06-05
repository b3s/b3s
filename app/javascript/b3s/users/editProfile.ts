import readyHandler from "../../lib/readyHandler";

readyHandler.ready(() => {
  if (document.querySelector(".edit_user_profile")) {
    const checkAdmin = () => {
      const adminCheckbox =
        document.querySelector<HTMLInputElement>("#user_admin");
      const moderatorCheckbox =
        document.querySelector<HTMLInputElement>("#user_moderator");
      const userAdminCheckbox =
        document.querySelector<HTMLInputElement>("#user_user_admin");

      if (adminCheckbox?.checked) {
        moderatorCheckbox!.checked = true;
        moderatorCheckbox!.disabled = true;
        userAdminCheckbox!.checked = true;
        userAdminCheckbox!.disabled = true;
      } else {
        moderatorCheckbox!.disabled = false;
        userAdminCheckbox!.disabled = false;
      }
    };

    const checkUserStatus = () => {
      const statusSelect =
        document.querySelector<HTMLSelectElement>("#user_status");
      const bannedUntilSelects = document.querySelectorAll<HTMLSelectElement>(
        ".banned-until select"
      );
      const status = statusSelect?.value;
      const disabled = !(status === "hiatus" || status === "time_out");

      bannedUntilSelects.forEach((select) => {
        select.disabled = disabled;
      });
    };

    document
      .querySelector("#user_admin")
      ?.addEventListener("change", checkAdmin);
    document
      .querySelector("#user_status")
      ?.addEventListener("change", checkUserStatus);

    checkAdmin();
    checkUserStatus();
  }
});
