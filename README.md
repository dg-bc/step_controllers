# step_controllers
在我截短加密通路的逻辑路径时，用来学习插入流水线寄存器和设计状态机的方法。

包含了两个工程:
|------------------------|----------------------------------------------|
|  step_controller       |顶层为**step_controller** 包括三步骤 add mul special_step|
|  step_controller_multi |顶层为**step_controller_multi** 包括四步骤 add mul special end，special_step重复工作两次|
