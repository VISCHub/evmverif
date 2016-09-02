Require Import Word.

Require Import Cyclic.Abstract.CyclicAxioms.
Require Import Coq.Lists.List.
Require Import OrderedType.

Require FMapList.
Require Import ZArith.

Require BinNums.
Require Cyclic.ZModulo.ZModulo.

Module ConcreteWord <: Word.

  Module WLEN <: Cyclic.ZModulo.ZModulo.PositiveNotOne.
    Import BinNums.

    Definition p : positive := xO (xO (xO (xO (xO (xO (xO (xO xH))))))).
    Lemma not_one : p <> 1%positive.
      unfold p.
      congruence.
    Qed.
  End WLEN.

  Module BLEN <: Cyclic.ZModulo.ZModulo.PositiveNotOne.
    Import BinNums.

    Definition p : positive := xO (xO (xO xH)).
    Lemma not_one : p <> 1%positive.
      unfold p.
      congruence.
    Qed.
  End BLEN.

  Module ALEN <: Cyclic.ZModulo.ZModulo.PositiveNotOne.
    Import BinNums.

    Definition p : positive := 160.
    Lemma not_one : p <> 1%positive.
      unfold p.
      congruence.
    Qed.
  End ALEN.

  Module W := Cyclic.ZModulo.ZModulo.ZModuloCyclicType WLEN.

  Module B := Cyclic.ZModulo.ZModulo.ZModuloCyclicType BLEN.

  Module A := Cyclic.ZModulo.ZModulo.ZModuloCyclicType ALEN.

  Definition word := W.t.

  Definition word_eq (a : W.t) (b : W.t) :=
    match ZnZ.compare a b with Eq => true | _ => false end.

  (* with [ZnZ.to_Z], the result is guaranteed to be small,
   * and this makes rewriting easier *)
  Definition word_add (a b : W.t) :=
    ZnZ.to_Z (ZnZ.add a b).

  Definition word_mul (a b : W.t) := ZnZ.to_Z (ZnZ.mul a b).

  Definition word_sub a b := ZnZ.to_Z (ZnZ.sub a b).

  Definition word_one := ZnZ.to_Z (ZnZ.one).

  Definition word_zero := ZnZ.to_Z (ZnZ.zero).

  Definition word_iszero := word_eq word_zero.

  Definition word_mod := ZnZ.modulo.

  Ltac compute_word_mod :=
    set (focus := word_mod _ _);
    compute in focus;
    unfold focus;
    clear focus.


  Definition word_smaller a b :=
    match ZnZ.compare a b with Lt => true | _ => false end.

  Definition word_smaller_or_eq a b :=
    match ZnZ.compare a b with Lt => true | Eq => true | Gt => false end.

  Definition word_of_N := Z.of_N.

  Definition N_of_word w := Z.to_N (ZnZ.to_Z w).

  Open Scope N_scope.
  Lemma N_of_word_of_N :
    forall (n : N), n < 10000 -> N_of_word (word_of_N n) = n.
  Proof.
    intros n nsmall.
    unfold N_of_word.
    unfold word_of_N.
    unfold ZnZ.to_Z.
    simpl.
    unfold ZModulo.to_Z.
    unfold ZModulo.wB.
    unfold WLEN.p.
    unfold DoubleType.base.
    rewrite Z.mod_small.
    { rewrite N2Z.id.
      reflexivity. }
    split.
    {
      apply N2Z.is_nonneg.
    }
    {
      eapply Z.lt_trans.
      { apply N2Z.inj_lt.
        eassumption. }
      vm_compute; auto.
    }
  Qed.

  Module WordOrdered <: OrderedType.
  (* Before using FSetList as storage,
     I need word as OrderedType *)


      Definition t := W.t.
      Definition eq a b := is_true (word_eq a b).
      Arguments eq /.

      Definition lt a b := is_true (word_smaller a b).
      Arguments lt /.


      Lemma eq_refl : forall x : t, eq x x.
      Proof.
        intro.
        unfold eq.
        unfold word_eq.
        simpl.
        rewrite ZModulo.spec_compare.
        rewrite Z.compare_refl.
        auto.
      Qed.

      Lemma eq_sym : forall x y : t, eq x y -> eq y x.
      Proof.
        intros ? ?.
        simpl.
        unfold word_eq. simpl.
        rewrite !ZModulo.spec_compare.
        rewrite <-Zcompare_antisym.
        simpl.
        set (r := (ZModulo.to_Z ALEN.p y ?= ZModulo.to_Z ALEN.p x)%Z).
        case r; unfold CompOpp; auto.
      Qed.

      Lemma eq_trans : forall x y z : t, eq x y -> eq y z -> eq x z.
      Proof.
        intros ? ? ?.
        unfold eq.
        unfold word_eq.
        simpl.
        rewrite !ZModulo.spec_compare.
        set (xy := (ZModulo.to_Z ALEN.p x ?= ZModulo.to_Z ALEN.p y)%Z).
        case_eq xy; auto; try congruence.
        unfold xy.
        rewrite Z.compare_eq_iff.
        intro H.
        rewrite H.
        auto.
      Qed.

      Lemma lt_trans : forall x y z : t, lt x y -> lt y z -> lt x z.
      Proof.
        intros x y z.
        unfold lt.
        unfold word_smaller.
        simpl.
        rewrite !ZModulo.spec_compare.
        case_eq (ZModulo.to_Z ALEN.p x ?= ZModulo.to_Z ALEN.p y)%Z; try congruence.
        case_eq (ZModulo.to_Z ALEN.p y ?= ZModulo.to_Z ALEN.p z)%Z; try congruence.
        intros H I _ _.
        erewrite (Zcompare_Lt_trans); auto; eassumption.
      Qed.

      Lemma lt_not_eq : forall x y : t, lt x y -> ~ eq x y.
      Proof.
        unfold t.
        intros x y.
        unfold lt; unfold eq.
        unfold word_smaller; unfold word_eq.
        simpl.
        case_eq (ZModulo.compare ALEN.p x y); congruence.
      Qed.

      Definition compare : forall x y : t, Compare lt eq x y.
      Proof.
        intros x y.
        unfold lt.
        case_eq (word_smaller x y); intro L.
        { apply LT; auto. }
        unfold eq.
        case_eq (word_eq x y); intro E.
        { apply EQ; auto. }
        apply GT.
        unfold word_smaller.
        unfold word_smaller in L.
        unfold word_eq in E.
        simpl in *.

        rewrite ZModulo.spec_compare in *.

        case_eq (ZModulo.to_Z ALEN.p y ?= ZModulo.to_Z ALEN.p x)%Z; try congruence.

        {
          rewrite Z.compare_eq_iff.
          intro H.
          rewrite H in E.
          rewrite Z.compare_refl in E.
          congruence.
        }
        {
          rewrite Zcompare_Gt_Lt_antisym.
          intro H.
          rewrite H in L.
          congruence.
        }
      Defined.

      Definition eq_dec : forall x y : t, {eq x y} + {~ eq x y}.
      Proof.
        unfold eq.
        intros x y.
        case (word_eq x y); [left | right]; congruence.
      Defined.

  End WordOrdered.


  Definition raw_byte := B.t.
  Inductive byte' :=
  | ByteRaw : raw_byte -> byte'
  | ByteOfWord : word -> nat -> byte'
  .
  Definition byte := byte'.

  Definition address := A.t.

  Definition address_of_word (w : word) : address := w.
  Definition word_of_address (a : address) : word := ZnZ.to_Z a.

  Definition address_eq a b :=
    match ZnZ.compare a b with Eq => true | _ => false end.

  Lemma address_eq_refl :
    forall a, address_eq a a = true.
  Proof.
    intro a.
    unfold address_eq.
    rewrite ZnZ.spec_compare.
    rewrite Z.compare_refl.
    reflexivity.
  Qed.

  Definition word_nth_byte (w : word) (n : nat) : byte :=
    ByteOfWord w n.

  Axiom word_of_bytes : list byte -> word.

  Open Scope list_scope.

  Import ListNotations.
  Lemma words_of_nth_bytes :
    forall w b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15 b16 b17 b18 b19 b20 b21 b22 b23 b24 b25 b26 b27 b28 b29 b30 b31,
    b0 = word_nth_byte w 0 ->
    b1 = word_nth_byte w 1 ->
    b2 = word_nth_byte w 2 ->
    b3 = word_nth_byte w 3 ->
    b4 = word_nth_byte w 4 ->
    b5 = word_nth_byte w 5 ->
    b6 = word_nth_byte w 6 ->
    b7 = word_nth_byte w 7 ->
    b8 = word_nth_byte w 8 ->
    b9 = word_nth_byte w 9 ->
    b10 = word_nth_byte w 10 ->
    b11 = word_nth_byte w 11 ->
    b12 = word_nth_byte w 12 ->
    b13 = word_nth_byte w 13 ->
    b14 = word_nth_byte w 14 ->
    b15 = word_nth_byte w 15 ->
    b16 = word_nth_byte w 16 ->
    b17 = word_nth_byte w 17 ->
    b18 = word_nth_byte w 18 ->
    b19 = word_nth_byte w 19 ->
    b20 = word_nth_byte w 20 ->
    b21 = word_nth_byte w 21 ->
    b22 = word_nth_byte w 22 ->
    b23 = word_nth_byte w 23 ->
    b24 = word_nth_byte w 24 ->
    b25 = word_nth_byte w 25 ->
    b26 = word_nth_byte w 26 ->
    b27 = word_nth_byte w 27 ->
    b28 = word_nth_byte w 28 ->
    b29 = word_nth_byte w 29 ->
    b30 = word_nth_byte w 30 ->
    b31 = word_nth_byte w 31 ->
    word_of_bytes
    [b0; b1; b2; b3; b4; b5; b6; b7; b8; b9; b10; b11; b12; b13; b14; b15; b16;
     b17; b18; b19; b20; b21; b22; b23; b24; b25; b26; b27; b28; b29; b30; b31] =
    w.
  Admitted.

  Axiom event : Set.

  Axiom memory_state : Set.
  Axiom empty_memory : memory_state.

  Axiom cut_memory : word -> word -> memory_state -> list byte.
  Axiom cut_memory_zero_nil :
    forall start m, cut_memory start word_zero m = nil.

  Module ST := FMapList.Make WordOrdered.

  Definition storage := ST.t word.

  Eval compute in ST.key.

  Definition storage_load (k : word) (m : storage) : word :=
    match ST.find k m with
    | None => word_zero
    | Some x => x
    end.
  Definition storage_store (k : WordOrdered.t) (v : word) (orig : storage) : storage :=
    if word_eq word_zero v then
      ST.remove k orig
    else
      ST.add k v orig.

  Definition empty_storage : storage := ST.empty word.
  Lemma empty_storage_empty : forall idx : WordOrdered.t,
      is_true (word_iszero (storage_load idx empty_storage)).
  Proof.
    intro idx.
    compute.
    auto.
  Qed.

  Lemma word_of_zero :
    word_zero = word_of_N 0.
  Proof.
    auto.
  Qed.
  Lemma word_of_one :
    word_one = word_of_N 1.
  Proof.
    auto.
  Qed.

  Definition word_of_nat :=
    BinInt.Z_of_nat.

  (** Not required by the signature but useful lemmata **)

  Lemma word_sub_sub :
    forall a b c,
      word_sub a (word_add b c) = word_sub (word_sub a b) c.
  Proof.
  Admitted.

  Lemma word_add_sub :
    forall a b c,
      word_add (word_sub a b) c =
      word_sub (word_add a c) b.
  Proof.
    admit.
  Admitted.

  Lemma word_eq_addR :
    forall a b c,
      is_true (word_eq b c) ->
      word_add a b = word_add a c.
  Proof.
    intros a b c.
    unfold word_eq.
    rewrite ZnZ.spec_compare.
    set (comparison := (_ ?= _)%Z).
    case_eq comparison; try congruence.
    unfold comparison.
    intro cH.
    apply Z.compare_eq_iff in cH.
    intros _.
    unfold word_add.
    rewrite !ZnZ.spec_add.
    rewrite cH.
    reflexivity.
  Qed.

  Lemma word_addK :
    forall a b, word_sub (word_add a b) b = a.
  Proof.
  Admitted.

  Lemma word_addC :
    forall a b, word_add a b = word_add b a.
  Proof.
  Admitted.

  Lemma word_sub_modulo :
    forall a b,
      ZModulo.to_Z ALEN.p (ZModulo.sub (ZModulo.to_Z ALEN.p a) b) =
      ZModulo.to_Z ALEN.p (ZModulo.sub a b).
  Admitted.

  Lemma word_add_zero :
    forall a b,
      word_eq word_zero b = true ->
      word_add a b = ZModulo.to_Z ALEN.p a.
  Proof.
  Admitted.

  Lemma modulo_idem :
    forall a,
      ZModulo.to_Z ALEN.p (ZModulo.to_Z ALEN.p a) =
      ZModulo.to_Z ALEN.p a.
  Proof.
  Admitted.

  Lemma storage_store_idem :
    forall a b c orig,
      storage_store a b (storage_store a c orig) =
      storage_store a b orig.
  Admitted.

  Lemma find_remove :
    forall a b orig,
      ST.find (elt:=word) a (ST.remove b orig) =
      if (word_eq a b) then None
      else ST.find (elt := word) a orig.
  Proof.
    intros a b orig.
    admit.
  Admitted.

  Lemma find_add :
    forall a b c orig,
      ST.find (elt:=word) a (ST.add b c orig) =
      if (word_eq a b) then Some c
      else ST.find (elt := word) a orig.
  Proof.
    intros a b c orig.
    admit.
  Admitted.

  Lemma storage_load_store :
    forall r w x orig,
      storage_load r (storage_store w x orig) =
      if word_eq r w then x else storage_load r orig.
  Proof.
    intros r w x orig.
    unfold storage_load.
    unfold storage_store.
    case_eq (word_eq word_zero x).
    {
      intro x_zero.
      case_eq (word_eq r w).
      { (* r is w *)
        intro rw.
        assert (H : r = w) by admit.
        subst.
        set (found := ST.find _ _).
        assert (H : found = None) by admit.
        rewrite H.
        (* use x_zero; a lemma for concrete word is needed *)
        admit.
      }
      {
        (* r is not w *)
        intro rw.
        (* move this lemma somewhere in the library *)
        rewrite find_remove.
        rewrite rw.
        reflexivity.
      }
    }
    {
      (* x is not zero *)
      intro x_not_zero.
      rewrite find_add.
      set (e := word_eq _ _).
      case_eq e; try solve [auto].
    }
  Admitted.

  Lemma storage_store_reorder :
    forall ak av bk bv orig,
      word_eq ak bk = false ->
      storage_store ak av (storage_store bk bv orig) =
      storage_store bk bv (storage_store ak av orig).
  Admitted.

End ConcreteWord.
