defmodule SievexTest.Sievex do
  use ExUnit.Case
  import Sievex

  describe "no do-block" do
    defmodule TestModuleNoDoBlock do
      defsieve something(_user_id, _subject_id), fallback: :deny_no, continue: nil
    end

    test "shows fallback correctly" do
      assert :deny_no == TestModuleNoDoBlock.something(2, 2)
    end
  end

  describe "empty do-block" do
    defmodule TestModuleEmptyDoBlock do
      defsieve something(_user_id, _subject_id), fallback: :deny_empty, continue: nil do end
    end

    test "shows fallback correctly" do
      assert :deny_empty == TestModuleEmptyDoBlock.something(2, 2)
    end
  end

  describe "incorrect do-block" do
    test "raises when atom" do
      assert_raise SyntaxError, fn ->
        defmodule TestModuleIncorrectDoBlockAtom do
          defsieve something(_user_id, _subject_id), fallback: :deny, continue: nil do
            :pass
          end
        end
      end
    end

    test "raises when nil" do
      assert_raise SyntaxError, fn ->
        defmodule TestModuleIncorrectDoBlockNil do
          defsieve something(_user_id, _subject_id), fallback: :deny, continue: nil do
            nil
          end
        end
      end
    end

    test "raises when free-form" do
      assert_raise SyntaxError, fn ->
        defmodule TestModuleIncorrectDoBlockFreeForm do
          defsieve something(_user_id, _subject_id), fallback: :deny, continue: nil do
            IO.inspect("this should not be run")

            1 + 1
          end
        end
      end
    end
  end

  describe "the easy case" do
    defmodule TestModuleEasyCase do
      defsieve something(user_id, subject_id), fallback: :deny, continue: nil do
        2, _ ->
          :allow

        _, 2 ->
          :oops
      end
    end

    test "processes correctly" do
      assert :allow == TestModuleEasyCase.something(2, 2)
      assert :oops == TestModuleEasyCase.something(1, 2)
      assert :deny == TestModuleEasyCase.something(1, 1)
    end
  end

  describe "continue" do
    defmodule TestModuleContinue do
      defsieve something(user_id, subject_id), fallback: :deny, continue: nil do
        1, _ ->
          nil

        1, _ ->
          :yahoo
      end
    end

    test "processes correctly" do
      assert :yahoo == TestModuleContinue.something(1, 0)
      assert :deny == TestModuleContinue.something(2, 0)
    end
  end
end